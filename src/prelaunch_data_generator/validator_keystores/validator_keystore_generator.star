shared_utils = import_module("../../shared_utils/shared_utils.star")
keystore_files_module = import_module("./keystore_files.star")
keystores_result = import_module("./generate_keystores_result.star")

NODE_KEYSTORES_OUTPUT_DIRPATH_FORMAT_STR = "/node-{0}-keystores{1}/"

# Qrysm keystores are encrypted with a password
QRYSM_PASSWORD = "password"
QRYSM_PASSWORD_FILEPATH_ON_GENERATOR = "/tmp/qrysm-password.txt"

KEYSTORES_GENERATION_TOOL_NAME = "/app/eth2-val-tools"

VAL_TOOLS_IMAGE = "qrledger/qrysm:qrl-genesis-generator-latest"

SUCCESSFUL_EXEC_CMD_EXIT_CODE = 0

QRYSM_DIRNAME = "qrysm"

KEYSTORE_GENERATION_FINISHED_FILEPATH_FORMAT = "/tmp/keystores_generated-{0}-{1}"

SERVICE_NAME_PREFIX = "validator-key-generation-"

ENTRYPOINT_ARGS = [
    "sleep",
    "99999",
]


# Launches a prelaunch data generator IMAGE, for use in various of the genesis generation
def launch_prelaunch_data_generator(
    plan,
    files_artifact_mountpoints,
    service_name_suffix,
    docker_cache_params,
):
    config = get_config(files_artifact_mountpoints, docker_cache_params)

    service_name = "{0}{1}".format(
        SERVICE_NAME_PREFIX,
        service_name_suffix,
    )
    plan.add_service(service_name, config)

    return service_name


def launch_prelaunch_data_generator_parallel(
    plan, files_artifact_mountpoints, service_name_suffixes, docker_cache_params
):
    config = get_config(files_artifact_mountpoints, docker_cache_params)
    service_names = [
        "{0}{1}".format(
            SERVICE_NAME_PREFIX,
            service_name_suffix,
        )
        for service_name_suffix in service_name_suffixes
    ]
    services_to_add = {service_name: config for service_name in service_names}
    plan.add_services(services_to_add)
    return service_names


def get_config(files_artifact_mountpoints, docker_cache_params):
    return ServiceConfig(
        image=shared_utils.docker_cache_image_calc(
            docker_cache_params,
            VAL_TOOLS_IMAGE,
        ),
        entrypoint=ENTRYPOINT_ARGS,
        files=files_artifact_mountpoints,
    )


# Generates keystores for the given number of nodes from the given mnemonic, where each keystore contains approximately
#
# 	num_keys / num_nodes keys
def generate_validator_keystores(plan, mnemonic, participants, docker_cache_params, light_kdf_enabled):
    service_name = launch_prelaunch_data_generator(
        plan, {}, "cl-validator-keystore", docker_cache_params
    )

    write_qrysm_password_file_cmd = [
        "sh",
        "-c",
        "echo '{0}' > {1}".format(
            QRYSM_PASSWORD,
            QRYSM_PASSWORD_FILEPATH_ON_GENERATOR,
        ),
    ]
    write_qrysm_password_file_cmd_result = plan.exec(
        service_name=service_name,
        description="Storing qrysm password in a file",
        recipe=ExecRecipe(command=write_qrysm_password_file_cmd),
    )
    plan.verify(
        write_qrysm_password_file_cmd_result["code"],
        "==",
        SUCCESSFUL_EXEC_CMD_EXIT_CODE,
    )

    qrysm_password_artifact_name = plan.store_service_files(
        service_name, QRYSM_PASSWORD_FILEPATH_ON_GENERATOR, name="qrysm-password"
    )

    all_output_dirpaths = []
    all_sub_command_strs = []
    running_total_validator_count = 0

    for idx, participant in enumerate(participants):
        output_dirpath = NODE_KEYSTORES_OUTPUT_DIRPATH_FORMAT_STR.format(idx, "")
        if participant.validator_count == 0:
            all_output_dirpaths.append(output_dirpath)
            continue
        generate_keystores_cmds = []

        start_index = running_total_validator_count
        generate_validator_keys_cmd = '{0} new-seed --validator-start-index {1} --num-validators {2} --folder {3} --mnemonic "{4}" --keystore-password-file={5} --chain-name "dev"'.format(
            "/usr/local/bin/deposit",
            start_index,
            participant.validator_count,
            shared_utils.path_join(output_dirpath, "validator_keys"),
            mnemonic,
            QRYSM_PASSWORD_FILEPATH_ON_GENERATOR,
        )
        if light_kdf_enabled:
            generate_validator_keys_cmd += " --lightkdf"
                
        generate_keystores_cmds.append(generate_validator_keys_cmd)
        create_validator_wallets_cmd = '{0} wallet create --accept-terms-of-use=true --wallet-dir={1} --keymanager-kind={2} --wallet-password-file={3}'.format(
            "/usr/local/bin/validator",
            shared_utils.path_join(output_dirpath, "qrysm"),
            "local",
            QRYSM_PASSWORD_FILEPATH_ON_GENERATOR,
        )
        generate_keystores_cmds.append(create_validator_wallets_cmd)

        import_validator_keys_cmd = '{0} accounts import --keys-dir={1} --wallet-dir={2} --wallet-password-file={3} --account-password-file={4}'.format(
            "/usr/local/bin/validator",
            shared_utils.path_join(output_dirpath, "validator_keys"),
            shared_utils.path_join(output_dirpath, "qrysm"),
            QRYSM_PASSWORD_FILEPATH_ON_GENERATOR,
            QRYSM_PASSWORD_FILEPATH_ON_GENERATOR,
        )
        generate_keystores_cmds.append(import_validator_keys_cmd)

        generate_keystores_cmd = " && ".join(generate_keystores_cmds)
        all_output_dirpaths.append(output_dirpath)
        all_sub_command_strs.append(generate_keystores_cmd)

        running_total_validator_count += participant.validator_count

    command_str = " && ".join(all_sub_command_strs)

    command_result = plan.exec(
        service_name=service_name,
        description="Generating keystores",
        recipe=ExecRecipe(command=["sh", "-c", command_str]),
    )
    plan.verify(command_result["code"], "==", SUCCESSFUL_EXEC_CMD_EXIT_CODE)

    # Store outputs into files artifacts
    keystore_files = []
    running_total_validator_count = 0
    for idx, participant in enumerate(participants):
        if participant.validator_count == 0:
            keystore_files.append(None)
            continue

        output_dirpath = NODE_KEYSTORES_OUTPUT_DIRPATH_FORMAT_STR.format(idx, "")
        padded_idx = shared_utils.zfill_custom(idx + 1, len(str(len(participants))))
        keystore_start_index = running_total_validator_count
        keystore_stop_index = (
            running_total_validator_count + participant.validator_count
        )

        artifact_name = "{0}-{1}-{2}-{3}-{4}".format(
            padded_idx,
            participant.cl_type,
            participant.el_type,
            keystore_start_index,
            keystore_stop_index - 1,
        )
        artifact_name = plan.store_service_files(
            service_name, output_dirpath, name=artifact_name
        )

        base_dirname_in_artifact = shared_utils.path_base(output_dirpath)
        to_add = keystore_files_module.new_keystore_files(
            artifact_name,
            shared_utils.path_join(base_dirname_in_artifact, QRYSM_DIRNAME),
        )

        keystore_files.append(to_add)

        running_total_validator_count += participant.validator_count

    result = keystores_result.new_generate_keystores_result(
        qrysm_password_artifact_name,
        shared_utils.path_base(QRYSM_PASSWORD_FILEPATH_ON_GENERATOR),
        keystore_files,
    )

    return result


# this is like above but runs things in parallel - for large networks that run on k8s or gigantic dockers
def generate_validator_keystores_in_parallel(
    plan, mnemonic, participants, docker_cache_params
):
    service_names = launch_prelaunch_data_generator_parallel(
        plan,
        {},
        ["cl-validator-keystore-" + str(idx) for idx in range(0, len(participants))],
        docker_cache_params,
    )
    all_output_dirpaths = []
    all_generation_commands = []
    finished_files_to_verify = []
    running_total_validator_count = 0
    for idx, participant in enumerate(participants):
        output_dirpath = NODE_KEYSTORES_OUTPUT_DIRPATH_FORMAT_STR.format(idx, "")
        if participant.validator_count == 0:
            all_generation_commands.append(None)
            all_output_dirpaths.append(None)
            finished_files_to_verify.append(None)
            continue
        start_index = running_total_validator_count
        running_total_validator_count += participant.validator_count
        stop_index = start_index + participant.validator_count
        generation_finished_filepath = (
            KEYSTORE_GENERATION_FINISHED_FILEPATH_FORMAT.format(start_index, stop_index)
        )
        finished_files_to_verify.append(generation_finished_filepath)

        generate_keystores_cmd = 'nohup {0} keystores --insecure --qrysm-pass {1} --out-loc {2} --source-mnemonic "{3}" --source-min {4} --source-max {5} && touch {6}'.format(
            KEYSTORES_GENERATION_TOOL_NAME,
            QRYSM_PASSWORD,
            output_dirpath,
            mnemonic,
            start_index,
            stop_index,
            generation_finished_filepath,
        )
        all_generation_commands.append(generate_keystores_cmd)
        all_output_dirpaths.append(output_dirpath)

    # spin up all jobs
    for idx in range(0, len(participants)):
        service_name = service_names[idx]
        generation_command = all_generation_commands[idx]
        if generation_command == None:
            # no generation command as validator count is 0
            continue
        plan.exec(
            service_name=service_name,
            description="Generating keystore for participant " + str(idx),
            recipe=ExecRecipe(
                command=["sh", "-c", generation_command + " >/dev/null 2>&1 &"]
            ),
        )

    # verify that files got created
    for idx in range(0, len(participants)):
        service_name = service_names[idx]
        output_dirpath = all_output_dirpaths[idx]
        if output_dirpath == None:
            # no output dir path as validator count is 0
            continue
        generation_finished_filepath = finished_files_to_verify[idx]
        verificaiton_command = ["ls", generation_finished_filepath]
        plan.wait(
            recipe=ExecRecipe(command=verificaiton_command),
            service_name=service_name,
            field="code",
            assertion="==",
            target_value=0,
            timeout="5m",
            interval="0.5s",
        )

    # Store outputs into files artifacts
    keystore_files = []
    running_total_validator_count = 0
    for idx, participant in enumerate(participants):
        output_dirpath = all_output_dirpaths[idx]
        if participant.validator_count == 0:
            keystore_files.append(None)
            continue
        service_name = service_names[idx]

        padded_idx = shared_utils.zfill_custom(idx + 1, len(str(len(participants))))
        keystore_start_index = running_total_validator_count
        running_total_validator_count += participant.validator_count
        keystore_stop_index = (keystore_start_index + participant.validator_count) - 1
        artifact_name = "{0}-{1}-{2}-{3}-{4}".format(
            padded_idx,
            participant.cl_type,
            participant.el_type,
            keystore_start_index,
            keystore_stop_index,
        )
        artifact_name = plan.store_service_files(
            service_name, output_dirpath, name=artifact_name
        )

        # This is necessary because the way Kurtosis currently implements artifact-storing is
        base_dirname_in_artifact = shared_utils.path_base(output_dirpath)
        to_add = keystore_files_module.new_keystore_files(
            artifact_name,
            shared_utils.path_join(base_dirname_in_artifact, QRYSM_DIRNAME),
        )

        keystore_files.append(to_add)

    write_qrysm_password_file_cmd = [
        "sh",
        "-c",
        "echo '{0}' > {1}".format(
            QRYSM_PASSWORD,
            QRYSM_PASSWORD_FILEPATH_ON_GENERATOR,
        ),
    ]
    write_qrysm_password_file_cmd_result = plan.exec(
        service_name=service_names[0],
        description="Storing qrysm password in a file",
        recipe=ExecRecipe(command=write_qrysm_password_file_cmd),
    )
    plan.verify(
        write_qrysm_password_file_cmd_result["code"],
        "==",
        SUCCESSFUL_EXEC_CMD_EXIT_CODE,
    )

    qrysm_password_artifact_name = plan.store_service_files(
        service_names[0], QRYSM_PASSWORD_FILEPATH_ON_GENERATOR, name="qrysm-password"
    )

    result = keystores_result.new_generate_keystores_result(
        qrysm_password_artifact_name,
        shared_utils.path_base(QRYSM_PASSWORD_FILEPATH_ON_GENERATOR),
        keystore_files,
    )

    # we don't cleanup the containers as its a costly operation
    return result
