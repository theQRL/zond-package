input_parser = import_module("../package_io/input_parser.star")
constants = import_module("../package_io/constants.star")
node_metrics = import_module("../node_metrics_info.star")
vc_context = import_module("./vc_context.star")

qrysm = import_module("./qrysm.star")
vc_shared = import_module("./shared.star")
shared_utils = import_module("../shared_utils/shared_utils.star")


def launch(
    plan,
    launcher,
    keymanager_file,
    service_name,
    vc_type,
    image,
    global_log_level,
    cl_context,
    el_context,
    remote_signer_context,
    full_name,
    snooper_enabled,
    snooper_beacon_context,
    node_keystore_files,
    participant,
    qrysm_password_relative_filepath,
    qrysm_password_artifact_uuid,
    global_tolerations,
    node_selectors,
    preset,
    network,  # TODO: remove when deneb rebase is done
    port_publisher,
    vc_index,
):
    if node_keystore_files == None:
        return None

    tolerations = input_parser.get_client_tolerations(
        participant.vc_tolerations, participant.tolerations, global_tolerations
    )

    if snooper_enabled:
        beacon_http_url = "http://{0}:{1}".format(
            snooper_beacon_context.ip_addr,
            snooper_beacon_context.beacon_rpc_port_num,
        )
    else:
        beacon_http_url = "{0}".format(
            cl_context.beacon_http_url,
        )

    keymanager_enabled = participant.keymanager_enabled
    if vc_type == constants.VC_TYPE.prysm:
        config = prysm.get_config(
            participant=participant,
            el_cl_genesis_data=launcher.el_cl_genesis_data,
            keymanager_file=keymanager_file,
            image=image,
            beacon_http_url=beacon_http_url,
            cl_context=cl_context,
            el_context=el_context,
            remote_signer_context=remote_signer_context,
            full_name=full_name,
            node_keystore_files=node_keystore_files,
            prysm_password_relative_filepath=prysm_password_relative_filepath,
            prysm_password_artifact_uuid=prysm_password_artifact_uuid,
            tolerations=tolerations,
            node_selectors=node_selectors,
            keymanager_enabled=keymanager_enabled,
            port_publisher=port_publisher,
            vc_index=vc_index,
        )
    else:
        fail("Unsupported vc_type: {0}".format(vc_type))

    validator_service = plan.add_service(service_name, config)

    validator_metrics_port = validator_service.ports[constants.METRICS_PORT_ID]
    validator_metrics_url = "{0}:{1}".format(
        validator_service.ip_address, validator_metrics_port.number
    )
    validator_node_metrics_info = node_metrics.new_node_metrics_info(
        service_name, vc_shared.METRICS_PATH, validator_metrics_url
    )

    return vc_context.new_vc_context(
        client_name=vc_type,
        service_name=service_name,
        metrics_info=validator_node_metrics_info,
    )


def new_vc_launcher(el_cl_genesis_data):
    return struct(el_cl_genesis_data=el_cl_genesis_data)
