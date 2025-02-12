shared_utils = import_module("../../shared_utils/shared_utils.star")
input_parser = import_module("../../package_io/input_parser.star")
remote_signer_context = import_module("../remote_signer_context.star")
# node_metrics = import_module("../../node_metrics_info.star")
constants = import_module("../../package_io/constants.star")

#  ---------------------------------- Beacon client -------------------------------------
BEACON_DATA_DIRPATH_ON_SERVICE_CONTAINER = "/data/qrysm/beacon-data/"

# Port nums
CLEF_HTTP_PORT_NUM = 8550
CLEF_HTTP_PORT_ID = "http"


CLEF_USED_PORTS = {
    CLEF_HTTP_PORT_ID: shared_utils.new_port_spec(
        CLEF_HTTP_PORT_NUM,
        shared_utils.TCP_PROTOCOL,
        shared_utils.HTTP_APPLICATION_PROTOCOL,
    ),
}


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
    service_name,
    image,
    participant,
    global_log_level,
    tolerations,
    node_selectors,
    port_publisher,
    remote_signer_index,
):
    log_level = input_parser.get_client_log_level_or_default(
        participant.el_log_level, global_log_level, VERBOSITY_LEVELS
    )

    clef_config = get_config(
        launcher=launcher,
        participant=participant,
        image=image,
        log_level=log_level,
        tolerations=tolerations,
        node_selectors=node_selectors,
        port_publisher=port_publisher,
        remote_signer_index=remote_signer_index,
    )

    clef_service = plan.add_service(service_name, clef_config)

    clef_http_port = clef_service.ports[CLEF_HTTP_PORT_ID]
    clef_http_url = "http://{0}:{1}".format(
        clef_service.ip_address, clef_http_port.number
    )

    return remote_signer_context.new_remote_signer_context(
        http_url=clef_http_url,
        client_name=constants.REMOTE_SIGNER_TYPE.clef,
        service_name=service_name,
        metrics_info=None,
    )


def get_config(
    launcher,
    participant,
    image,
    log_level,
    tolerations,
    node_selectors,
    port_publisher,
    remote_signer_index,
):
    cmd = [
        "clef",
        "--loglevel={0}".format(log_level),
        # "--keystore={0}".format(""),
        # "--configdir={0}".format(""),
        "--chainid={0}".format(launcher.networkid),
        "--http.addr=0.0.0.0",
        "--http.vhosts={0}".format("*"),
        "--http",
        "--http.port={0}".format(CLEF_HTTP_PORT_NUM),
        "--suppress-bootwarn",
    ]

    if len(participant.remote_signer_extra_params) > 0:
        # this is a repeated<proto type>, we convert it into Starlark
        cmd.extend([param for param in participant.remote_signer_extra_params])

    files = {
        # constants.JWT_MOUNTPOINT_ON_CLIENTS: launcher.jwt_file,
    }

    public_ports = {}
    if port_publisher.remote_signer_enabled:
        public_ports_for_component = shared_utils.get_public_ports_for_component(
            "remote-signer", port_publisher, remote_signer_index
        )
        public_port_assignments = {
            # constants.METRICS_PORT_ID: public_ports_for_component[0]
        }
        public_ports = shared_utils.get_port_specs(public_port_assignments)

    ports = {}
    ports.update(CLEF_USED_PORTS)

    config_args = {
        "image": image,
        "ports": ports,
        "public_ports": public_ports,
        "cmd": cmd,
        # "files": files,
        "env_vars": participant.remote_signer_extra_env_vars,
        "labels": shared_utils.label_maker(
            client=constants.REMOTE_SIGNER_TYPE.clef,
            client_type=constants.CLIENT_TYPES.remote_signer,
            image=image,
            extra_labels=participant.remote_signer_extra_labels,
            supernode=participant.supernode,
        ),
        "tolerations": tolerations,
        "node_selectors": node_selectors,
    }

    if participant.remote_signer_min_cpu > 0:
        config_args["min_cpu"] = participant.remote_signer_min_cpu
    if participant.remote_signer_max_cpu > 0:
        config_args["max_cpu"] = participant.remote_signer_max_cpu
    if participant.remote_signer_min_mem > 0:
        config_args["min_memory"] = participant.remote_signer_min_mem
    if participant.remote_signer_max_mem > 0:
        config_args["max_memory"] = participant.remote_signer_max_mem
    return ServiceConfig(**config_args)


def new_clef_launcher(
    networkid,
    rules_file,
):
    return struct(
        networkid=networkid,
        rules_file=rules_file,
    )
