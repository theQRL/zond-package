shared_utils = import_module("../../shared_utils/shared_utils.star")
input_parser = import_module("../../package_io/input_parser.star")
remote_signer_context = import_module("../../remote_signer/remote_signer_context.star")
cl_node_ready_conditions = import_module("../../cl/cl_node_ready_conditions.star")
cl_shared = import_module("../cl_shared.star")
node_metrics = import_module("../../node_metrics_info.star")
constants = import_module("../../package_io/constants.star")

#  ---------------------------------- Beacon client -------------------------------------
BEACON_DATA_DIRPATH_ON_SERVICE_CONTAINER = "/data/qrysm/beacon-data/"

# Port nums
CLEF_HTTP_PORT_NUM = 8550

VERBOSITY_LEVELS = {
    constants.GLOBAL_LOG_LEVEL.error: "1",
    constants.GLOBAL_LOG_LEVEL.warn: "2",
    constants.GLOBAL_LOG_LEVEL.info: "3",
    constants.GLOBAL_LOG_LEVEL.debug: "4",
    constants.GLOBAL_LOG_LEVEL.trace: "5",
}

# The min/max CPU/memory that the remote signer can use
MIN_CPU = 50
MAX_CPU = 300
MIN_MEMORY = 128
MAX_MEMORY = 1024

def launch(
    plan,
    launcher,
    beacon_service_name,
    participant,
    global_log_level,
    bootnode_contexts,
    el_context,
    full_name,
    node_keystore_files,
    snooper_engine_context,
    persistent,
    tolerations,
    node_selectors,
    checkpoint_sync_enabled,
    checkpoint_sync_url,
    port_publisher,
    participant_index,
):
    log_level = input_parser.get_client_log_level_or_default(
        participant.el_log_level, global_log_level, VERBOSITY_LEVELS
    )

    clef_config = get_clef_config(
        plan,
        launcher,
        beacon_service_name,
        participant,
        log_level,
        bootnode_contexts,
        el_context,
        full_name,
        node_keystore_files,
        snooper_engine_context,
        persistent,
        tolerations,
        node_selectors,
        checkpoint_sync_enabled,
        checkpoint_sync_url,
        port_publisher,
        participant_index,
    )

    clef_service = plan.add_service(clef_service_name, clef_config)

    beacon_http_port = beacon_service.ports[constants.HTTP_PORT_ID]

    beacon_http_url = "http://{0}:{1}".format(
        beacon_service.ip_address, BEACON_HTTP_PORT_NUM
    )
    beacon_grpc_url = "{0}:{1}".format(beacon_service.ip_address, RPC_PORT_NUM)

    # TODO(old) add validator availability using the validator API: https://ethereum.github.io/beacon-APIs/?urls.primaryName=v1#/ValidatorRequiredApi | from eth2-merge-kurtosis-module
    beacon_node_identity_recipe = GetHttpRequestRecipe(
        endpoint="/zond/v1/node/identity",
        port_id=constants.HTTP_PORT_ID,
        extract={
            "enr": ".data.enr",
            "multiaddr": ".data.p2p_addresses[0]",
            "peer_id": ".data.peer_id",
        },
    )
    response = plan.request(
        recipe=beacon_node_identity_recipe, service_name=beacon_service_name
    )
    beacon_node_enr = response["extract.enr"]
    beacon_multiaddr = response["extract.multiaddr"]
    beacon_peer_id = response["extract.peer_id"]

    beacon_metrics_port = beacon_service.ports[constants.METRICS_PORT_ID]
    beacon_metrics_url = "{0}:{1}".format(
        beacon_service.ip_address, beacon_metrics_port.number
    )
    beacon_node_metrics_info = node_metrics.new_node_metrics_info(
        beacon_service_name, METRICS_PATH, beacon_metrics_url
    )
    nodes_metrics_info = [beacon_node_metrics_info]

    return remote_signer_context.new_remote_signer_context(
        http_url=remote_signer_http_url,
        client_name=remote_signer_type,
        service_name=service_name,
        metrics_info=remote_signer_node_metrics_info,
    )


def get_clef_config(
    plan,
    launcher,
    beacon_service_name,
    participant,
    log_level,
    bootnode_contexts,
    el_context,
    full_name,
    node_keystore_files,
    snooper_engine_context,
    persistent,
    tolerations,
    node_selectors,
    checkpoint_sync_enabled,
    checkpoint_sync_url,
    port_publisher,
    participant_index,
):
    public_ports = {}
    discovery_port = DISCOVERY_TCP_PORT_NUM
    discovery_port_udp = DISCOVERY_UDP_PORT_NUM
    discovery_port_quic = DISCOVERY_QUIC_PORT_NUM
    if port_publisher.cl_enabled:
        public_ports_for_component = shared_utils.get_public_ports_for_component(
            "cl", port_publisher, participant_index
        )
        public_ports, discovery_port = cl_shared.get_general_cl_public_port_specs(
            public_ports_for_component
        )
        public_ports.update(
            shared_utils.get_port_specs(
                {constants.RPC_PORT_ID: public_ports_for_component[3]}
            )
        )
        public_ports.update(
            shared_utils.get_port_specs(
                {constants.PROFILING_PORT_ID: public_ports_for_component[4]}
            )
        )

    used_port_assignments = {
        constants.TCP_DISCOVERY_PORT_ID: discovery_port,
        constants.UDP_DISCOVERY_PORT_ID: discovery_port_udp,
        # constants.QUIC_DISCOVERY_PORT_ID: discovery_port_quic, # TODO: Uncomment this when we have a stable release with this flag
        constants.HTTP_PORT_ID: BEACON_HTTP_PORT_NUM,
        constants.METRICS_PORT_ID: BEACON_MONITORING_PORT_NUM,
        constants.RPC_PORT_ID: RPC_PORT_NUM,
        constants.PROFILING_PORT_ID: PROFILING_PORT_NUM,
    }
    used_ports = shared_utils.get_port_specs(used_port_assignments)

    cmd = [
        "clef",
        "--suppress-bootwarn",
        "--configdir=",
        "--keystore=",
        "--rules",
        "--auditlog",
        "--chainid={0}".format(launcher.networkid),
        "--http"
    ]

    # files = {
    #     constants.JWT_MOUNTPOINT_ON_CLIENTS: launcher.jwt_file,
    # }

    config_args = {
        "image": participant.cl_image,
        "ports": used_ports,
        "public_ports": public_ports,
        "cmd": cmd,
        "files": files,
        "env_vars": participant.cl_extra_env_vars,
        "private_ip_address_placeholder": constants.PRIVATE_IP_ADDRESS_PLACEHOLDER,
        "ready_conditions": cl_node_ready_conditions.get_ready_conditions(
            constants.HTTP_PORT_ID
        ),
        "labels": shared_utils.label_maker(
            client=constants.CL_TYPE.qrysm,
            client_type=constants.CLIENT_TYPES.cl,
            image=participant.cl_image[-constants.MAX_LABEL_LENGTH :],
            connected_client=el_context.client_name,
            extra_labels=participant.cl_extra_labels,
            supernode=participant.supernode,
        ),
        "tolerations": tolerations,
        "node_selectors": node_selectors,
    }

    if int(participant.cl_min_cpu) > 0:
        config_args["min_cpu"] = int(participant.cl_min_cpu)
    if int(participant.cl_max_cpu) > 0:
        config_args["max_cpu"] = int(participant.cl_max_cpu)
    if int(participant.cl_min_mem) > 0:
        config_args["min_memory"] = int(participant.cl_min_mem)
    if int(participant.cl_max_mem) > 0:
        config_args["max_memory"] = int(participant.cl_max_mem)
    return ServiceConfig(**config_args)


def new_clef_launcher(
    networkid,
    rules_file,
):
    return struct(
        networkid=networkid,
        rules_file=rules_file,
    )
