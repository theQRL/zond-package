shared_utils = import_module("../../shared_utils/shared_utils.star")
keystore_file_module = import_module("./keystore_file.star")
keystore_result = import_module("./generate_keystore_result.star")

CLEF_KEYSTORE_OUTPUT_DIRPATH = "/clef-keystore/"

# Clef key is encrypted with a passphrase (>=10 characters)
CLEF_KEY_PASSWORD = "passwordpassword"
CLEF_KEY_PASSWORD_FILEPATH_ON_GENERATOR = "/tmp/clef-key-password.txt"
CLEF_KEY_SEED_FILEPATH_ON_GENERATOR = "/tmp/clef-key-seed.txt"

GZOND_TOOLS_IMAGE = "theqrl/gzond-alltools:latest"

SUCCESSFUL_EXEC_CMD_EXIT_CODE = 0

CLEF_DIRNAME = "clef"

SERVICE_NAME_PREFIX = "clef-keystore-generation-"

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


def get_config(files_artifact_mountpoints, docker_cache_params):
    return ServiceConfig(
        image=shared_utils.docker_cache_image_calc(
            docker_cache_params,
            GZOND_TOOLS_IMAGE,
        ),
        entrypoint=ENTRYPOINT_ARGS,
        files=files_artifact_mountpoints,
    )


# Generates keystore for clef agent
def generate_clef_keystore(plan, prefunded_account, participants, docker_cache_params):
    service_name = launch_prelaunch_data_generator(
        plan, {}, "el-clef-keystore", docker_cache_params
    )

    # Clef key password file
    write_clef_key_password_file_cmd = [
        "sh",
        "-c",
        "echo '{0}' > {1}".format(
            CLEF_KEY_PASSWORD,
            CLEF_KEY_PASSWORD_FILEPATH_ON_GENERATOR,
        ),
    ]
    write_clef_key_password_file_cmd_result = plan.exec(
        service_name=service_name,
        description="Storing clef key password in a file",
        recipe=ExecRecipe(command=write_clef_key_password_file_cmd),
    )
    plan.verify(
        write_clef_key_password_file_cmd_result["code"],
        "==",
        SUCCESSFUL_EXEC_CMD_EXIT_CODE,
    )

    clef_key_password_artifact_name = plan.store_service_files(
        service_name, CLEF_KEY_PASSWORD_FILEPATH_ON_GENERATOR, name="clef-key-password"
    )

    # Clef key seed file
    write_clef_key_seed_file_cmd = [
        "sh",
        "-c",
        "echo '{0}' > {1}".format(
            prefunded_account.seed,
            CLEF_KEY_SEED_FILEPATH_ON_GENERATOR,
        ),
    ]
    write_clef_key_seed_file_cmd_result = plan.exec(
        service_name=service_name,
        description="Storing clef key seed in a file",
        recipe=ExecRecipe(command=write_clef_key_seed_file_cmd),
    )
    plan.verify(
        write_clef_key_seed_file_cmd_result["code"],
        "==",
        SUCCESSFUL_EXEC_CMD_EXIT_CODE,
    )

    clef_key_seed_artifact_name = plan.store_service_files(
        service_name, CLEF_KEY_SEED_FILEPATH_ON_GENERATOR, name="clef-key-seed"
    )

    output_dirpath = CLEF_KEYSTORE_OUTPUT_DIRPATH

    import_clef_key_cmd = '{0} --suppress-bootwarn --keystore={1} importraw --password={2} {3} '.format(
        "clef",
        shared_utils.path_join(output_dirpath, "keystore"),
        CLEF_KEY_PASSWORD_FILEPATH_ON_GENERATOR,
        CLEF_KEY_SEED_FILEPATH_ON_GENERATOR,
    )

    command_result = plan.exec(
        service_name=service_name,
        description="Generating keystore",
        recipe=ExecRecipe(command=["sh", "-c", import_clef_key_cmd]),
    )
    plan.verify(command_result["code"], "==", SUCCESSFUL_EXEC_CMD_EXIT_CODE)

    # Store output into file artifact    
    # artifact_name = plan.store_service_files(
    #     service_name, output_dirpath, name="clef-0"
    # )

    # base_dirname_in_artifact = shared_utils.path_base(output_dirpath)
    # keystore_file = keystore_files_module.new_keystore_files(
    #     artifact_name,
    #     shared_utils.path_join(base_dirname_in_artifact, CLEF_DIRNAME),
    # )

    # running_total_validator_count += participant.validator_count

    # result = keystores_result.new_generate_keystore_result(
    #     clef_account_password_artifact_name,
    #     shared_utils.path_base(CLEF_KEY_PASSWORD_FILEPATH_ON_GENERATOR),
    #     keystore_file,
    # )

    # return result
    return None