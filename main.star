input_parser = import_module("./src/package_io/input_parser.star")
constants = import_module("./src/package_io/constants.star")
participant_network = import_module("./src/participant_network.star")
shared_utils = import_module("./src/shared_utils/shared_utils.star")
static_files = import_module("./src/static_files/static_files.star")
genesis_constants = import_module(
    "./src/prelaunch_data_generator/genesis_constants/genesis_constants.star"
)

validator_ranges = import_module(
    "./src/prelaunch_data_generator/validator_keystores/validator_ranges_generator.star"
)

transaction_spammer = import_module(
    "./src/transaction_spammer/transaction_spammer.star"
)
el_forkmon = import_module("./src/el_forkmon/el_forkmon_launcher.star")
beacon_metrics_gazer = import_module(
    "./src/beacon_metrics_gazer/beacon_metrics_gazer_launcher.star"
)
explorer = import_module("./src/explorer/explorer_launcher.star")
dugtrio = import_module("./src/dugtrio/dugtrio_launcher.star")
blutgang = import_module("./src/blutgang/blutgang_launcher.star")
forky = import_module("./src/forky/forky_launcher.star")
tracoor = import_module("./src/tracoor/tracoor_launcher.star")
apache = import_module("./src/apache/apache_launcher.star")
full_beaconchain_explorer = import_module(
    "./src/full_beaconchain/full_beaconchain_launcher.star"
)
prometheus = import_module("./src/prometheus/prometheus_launcher.star")
grafana = import_module("./src/grafana/grafana_launcher.star")
broadcaster = import_module("./src/broadcaster/broadcaster.star")
assertoor = import_module("./src/assertoor/assertoor_launcher.star")
get_prefunded_accounts = import_module(
    "./src/prefunded_accounts/get_prefunded_accounts.star"
)
spamoor = import_module("./src/spamoor/spamoor.star")

GRAFANA_USER = "admin"
GRAFANA_PASSWORD = "admin"
GRAFANA_DASHBOARD_PATH_URL = "/d/QdTOwy-nz/eth2-merge-kurtosis-module-dashboard?orgId=1"

FIRST_NODE_FINALIZATION_FACT = "cl-boot-finalization-fact"
HTTP_PORT_ID_FOR_FACT = "http"


def run(plan, args={}):
    """Launches an arbitrarily complex zond testnet based on the arguments provided

    Args:
        args: A YAML or JSON argument to configure the network; example https://github.com/theQRL/zond-package/blob/main/network_params.yaml
    """

    args_with_right_defaults = input_parser.input_parser(plan, args)

    num_participants = len(args_with_right_defaults.participants)
    network_params = args_with_right_defaults.network_params
    parallel_keystore_generation = args_with_right_defaults.parallel_keystore_generation
    persistent = args_with_right_defaults.persistent
    xatu_sentry_params = args_with_right_defaults.xatu_sentry_params
    global_tolerations = args_with_right_defaults.global_tolerations
    global_node_selectors = args_with_right_defaults.global_node_selectors
    keymanager_enabled = args_with_right_defaults.keymanager_enabled
    apache_port = args_with_right_defaults.apache_port
    docker_cache_params = args_with_right_defaults.docker_cache_params

    prefunded_accounts = genesis_constants.PRE_FUNDED_ACCOUNTS
    if (
        network_params.preregistered_validator_keys_mnemonic
        != constants.DEFAULT_MNEMONIC
    ):
        prefunded_accounts = get_prefunded_accounts.get_accounts(
            plan, network_params.preregistered_validator_keys_mnemonic
        )

    grafana_datasource_config_template = read_file(
        static_files.GRAFANA_DATASOURCE_CONFIG_TEMPLATE_FILEPATH
    )
    grafana_dashboards_config_template = read_file(
        static_files.GRAFANA_DASHBOARD_PROVIDERS_CONFIG_TEMPLATE_FILEPATH
    )
    prometheus_additional_metrics_jobs = []
    raw_jwt_secret = read_file(static_files.JWT_PATH_FILEPATH)
    jwt_file = plan.upload_files(
        src=static_files.JWT_PATH_FILEPATH,
        name="jwt_file",
    )
    keymanager_file = plan.upload_files(
        src=static_files.KEYMANAGER_PATH_FILEPATH,
        name="keymanager_file",
    )

    plan.print("Read the prometheus, grafana templates")

    plan.print(
        "Launching participant network with {0} participants and the following network params {1}".format(
            num_participants, network_params
        )
    )
    (
        all_participants,
        final_genesis_timestamp,
        el_cl_data_files_artifact_uuid,
        network_id,
    ) = participant_network.launch_participant_network(
        plan,
        args_with_right_defaults,
        network_params,
        jwt_file,
        keymanager_file,
        persistent,
        xatu_sentry_params,
        global_tolerations,
        global_node_selectors,
        keymanager_enabled,
        parallel_keystore_generation,
    )

    plan.print(
        "NODE JSON RPC URI: '{0}:{1}'".format(
            all_participants[0].el_context.ip_addr,
            all_participants[0].el_context.rpc_port_num,
        )
    )

    all_el_contexts = []
    all_cl_contexts = []
    all_vc_contexts = []
    all_remote_signer_contexts = []
    all_zond_metrics_exporter_contexts = []
    all_xatu_sentry_contexts = []
    for participant in all_participants:
        all_el_contexts.append(participant.el_context)
        all_cl_contexts.append(participant.cl_context)
        all_vc_contexts.append(participant.vc_context)
        all_remote_signer_contexts.append(participant.remote_signer_context)
        all_zond_metrics_exporter_contexts.append(
            participant.zond_metrics_exporter_context
        )
        all_xatu_sentry_contexts.append(participant.xatu_sentry_context)

    # Generate validator ranges
    validator_ranges_config_template = read_file(
        static_files.VALIDATOR_RANGES_CONFIG_TEMPLATE_FILEPATH
    )
    ranges = validator_ranges.generate_validator_ranges(
        plan,
        validator_ranges_config_template,
        all_participants,
        args_with_right_defaults.participants,
    )

    fuzz_target = "http://{0}:{1}".format(
        all_el_contexts[0].ip_addr,
        all_el_contexts[0].rpc_port_num,
    )

    # Broadcaster forwards requests, sent to it, to all nodes in parallel
    if "broadcaster" in args_with_right_defaults.additional_services:
        args_with_right_defaults.additional_services.remove("broadcaster")
        broadcaster_service = broadcaster.launch_broadcaster(
            plan,
            all_el_contexts,
            global_node_selectors,
        )
        fuzz_target = "http://{0}:{1}".format(
            broadcaster_service.ip_address,
            broadcaster.PORT,
        )

    if len(args_with_right_defaults.additional_services) == 0:
        output = struct(
            all_participants=all_participants,
            pre_funded_accounts=prefunded_accounts,
            network_params=network_params,
            network_id=network_id,
            final_genesis_timestamp=final_genesis_timestamp,
        )

        return output

    launch_prometheus_grafana = False
    for index, additional_service in enumerate(
        args_with_right_defaults.additional_services
    ):
        if additional_service == "tx_spammer":
            plan.print("Launching transaction spammer")
            tx_spammer_params = args_with_right_defaults.tx_spammer_params
            transaction_spammer.launch_transaction_spammer(
                plan,
                prefunded_accounts,
                fuzz_target,
                tx_spammer_params,
                global_node_selectors,
            )
            plan.print("Successfully launched transaction spammer")
        # We need a way to do time.sleep
        # TODO add code that waits for CL genesis
        elif additional_service == "el_forkmon":
            plan.print("Launching el forkmon")
            el_forkmon_config_template = read_file(
                static_files.EL_FORKMON_CONFIG_TEMPLATE_FILEPATH
            )
            el_forkmon.launch_el_forkmon(
                plan,
                el_forkmon_config_template,
                all_el_contexts,
                global_node_selectors,
                args_with_right_defaults.port_publisher,
                index,
                args_with_right_defaults.docker_cache_params,
            )
            plan.print("Successfully launched execution layer forkmon")
        elif additional_service == "beacon_metrics_gazer":
            plan.print("Launching beacon metrics gazer")
            beacon_metrics_gazer_prometheus_metrics_job = (
                beacon_metrics_gazer.launch_beacon_metrics_gazer(
                    plan,
                    all_cl_contexts,
                    network_params,
                    global_node_selectors,
                    args_with_right_defaults.port_publisher,
                    index,
                    args_with_right_defaults.docker_cache_params,
                )
            )
            launch_prometheus_grafana = True
            prometheus_additional_metrics_jobs.append(
                beacon_metrics_gazer_prometheus_metrics_job
            )
            plan.print("Successfully launched beacon metrics gazer")
        elif additional_service == "explorer":
            plan.print("Launching explorer")
            explorer_config_template = read_file(static_files.EXPLORER_CONFIG_TEMPLATE_FILEPATH)
            explorer_params = args_with_right_defaults.explorer_params
            explorer.launch_explorer(
                plan,
                explorer_config_template,
                all_participants,
                args_with_right_defaults.participants,
                network_params,
                explorer_params,
                global_node_selectors,
                args_with_right_defaults.port_publisher,
                index,
            )
            plan.print("Successfully launched explorer")
        elif additional_service == "dugtrio":
            plan.print("Launching dugtrio")
            dugtrio_config_template = read_file(
                static_files.DUGTRIO_CONFIG_TEMPLATE_FILEPATH
            )
            dugtrio.launch_dugtrio(
                plan,
                dugtrio_config_template,
                all_participants,
                args_with_right_defaults.participants,
                network_params,
                global_node_selectors,
                args_with_right_defaults.port_publisher,
                index,
                args_with_right_defaults.docker_cache_params,
            )
            plan.print("Successfully launched dugtrio")
        elif additional_service == "blutgang":
            plan.print("Launching blutgang")
            blutgang_config_template = read_file(
                static_files.BLUTGANG_CONFIG_TEMPLATE_FILEPATH
            )
            blutgang.launch_blutgang(
                plan,
                blutgang_config_template,
                all_participants,
                args_with_right_defaults.participants,
                network_params,
                global_node_selectors,
                args_with_right_defaults.port_publisher,
                index,
                args_with_right_defaults.docker_cache_params,
            )
            plan.print("Successfully launched blutgang")
        elif additional_service == "forky":
            plan.print("Launching forky")
            forky_config_template = read_file(
                static_files.FORKY_CONFIG_TEMPLATE_FILEPATH
            )
            forky.launch_forky(
                plan,
                forky_config_template,
                all_participants,
                args_with_right_defaults.participants,
                el_cl_data_files_artifact_uuid,
                network_params,
                global_node_selectors,
                final_genesis_timestamp,
                args_with_right_defaults.port_publisher,
                index,
                args_with_right_defaults.docker_cache_params,
            )
            plan.print("Successfully launched forky")
        elif additional_service == "tracoor":
            plan.print("Launching tracoor")
            tracoor_config_template = read_file(
                static_files.TRACOOR_CONFIG_TEMPLATE_FILEPATH
            )
            tracoor.launch_tracoor(
                plan,
                tracoor_config_template,
                all_participants,
                args_with_right_defaults.participants,
                el_cl_data_files_artifact_uuid,
                network_params,
                global_node_selectors,
                final_genesis_timestamp,
                args_with_right_defaults.port_publisher,
                index,
                args_with_right_defaults.docker_cache_params,
            )
            plan.print("Successfully launched tracoor")
        elif additional_service == "apache":
            plan.print("Launching apache")
            apache.launch_apache(
                plan,
                el_cl_data_files_artifact_uuid,
                apache_port,
                all_participants,
                args_with_right_defaults.participants,
                global_node_selectors,
                args_with_right_defaults.docker_cache_params,
            )
            plan.print("Successfully launched apache")
        elif additional_service == "full_beaconchain_explorer":
            plan.print("Launching full-beaconchain-explorer")
            full_beaconchain_explorer_config_template = read_file(
                static_files.FULL_BEACONCHAIN_CONFIG_TEMPLATE_FILEPATH
            )
            full_beaconchain_explorer.launch_full_beacon(
                plan,
                full_beaconchain_explorer_config_template,
                el_cl_data_files_artifact_uuid,
                all_cl_contexts,
                all_el_contexts,
                persistent,
                global_node_selectors,
                args_with_right_defaults.port_publisher,
                index,
            )
            plan.print("Successfully launched full-beaconchain-explorer")
        elif additional_service == "prometheus_grafana":
            # Allow prometheus to be launched last so is able to collect metrics from other services
            launch_prometheus_grafana = True
        elif additional_service == "assertoor":
            plan.print("Launching assertoor")
            assertoor_config_template = read_file(
                static_files.ASSERTOOR_CONFIG_TEMPLATE_FILEPATH
            )
            assertoor_params = args_with_right_defaults.assertoor_params
            assertoor.launch_assertoor(
                plan,
                assertoor_config_template,
                all_participants,
                args_with_right_defaults.participants,
                network_params,
                assertoor_params,
                global_node_selectors,
            )
            plan.print("Successfully launched assertoor")
        elif additional_service == "spamoor":
            plan.print("Launching spamoor")
            spamoor.launch_spamoor(
                plan,
                prefunded_accounts,
                all_el_contexts,
                args_with_right_defaults.spamoor_params,
                global_node_selectors,
            )
        else:
            fail("Invalid additional service %s" % (additional_service))
    if launch_prometheus_grafana:
        plan.print("Launching prometheus...")
        prometheus_private_url = prometheus.launch_prometheus(
            plan,
            all_el_contexts,
            all_cl_contexts,
            all_vc_contexts,
            all_remote_signer_contexts,
            prometheus_additional_metrics_jobs,
            all_zond_metrics_exporter_contexts,
            all_xatu_sentry_contexts,
            global_node_selectors,
            args_with_right_defaults.prometheus_params,
        )

        plan.print("Launching grafana...")
        grafana.launch_grafana(
            plan,
            grafana_datasource_config_template,
            grafana_dashboards_config_template,
            prometheus_private_url,
            global_node_selectors,
            args_with_right_defaults.grafana_params,
        )
        plan.print("Successfully launched grafana")

    if args_with_right_defaults.wait_for_finalization:
        plan.print("Waiting for the first finalized epoch")
        first_cl_client = all_cl_contexts[0]
        first_client_beacon_name = first_cl_client.beacon_service_name
        epoch_recipe = GetHttpRequestRecipe(
            endpoint="/zond/v1/beacon/states/head/finality_checkpoints",
            port_id=HTTP_PORT_ID_FOR_FACT,
            extract={"finalized_epoch": ".data.finalized.epoch"},
        )
        plan.wait(
            recipe=epoch_recipe,
            field="extract.finalized_epoch",
            assertion="!=",
            target_value="0",
            timeout="40m",
            service_name=first_client_beacon_name,
        )
        plan.print("First finalized epoch occurred successfully")

    grafana_info = struct(
        dashboard_path=GRAFANA_DASHBOARD_PATH_URL,
        user=GRAFANA_USER,
        password=GRAFANA_PASSWORD,
    )

    output = struct(
        grafana_info=grafana_info,
        all_participants=all_participants,
        pre_funded_accounts=prefunded_accounts,
        network_params=network_params,
        network_id=network_id,
        final_genesis_timestamp=final_genesis_timestamp,
    )

    return output
