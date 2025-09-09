shared_utils = import_module("../shared_utils/shared_utils.star")
static_files = import_module("../static_files/static_files.star")
qrl_metrics_exporter_context = import_module(
    "../qrl_metrics_exporter/qrl_metrics_exporter_context.star"
)

HTTP_PORT_ID = "http"
METRICS_PORT_NUMBER = 9090

DEFAULT_QRL_METRICS_EXPORTER_IMAGE = "qrledger/qrl-metrics-exporter:0.22.0"

# The min/max CPU/memory that qrl-metrics-exporter can use
MIN_CPU = 10
MAX_CPU = 100
MIN_MEMORY = 16
MAX_MEMORY = 128


def launch(
    plan,
    pair_name,
    qrl_metrics_exporter_service_name,
    el_context,
    cl_context,
    node_selectors,
    docker_cache_params,
):
    exporter_service = plan.add_service(
        qrl_metrics_exporter_service_name,
        ServiceConfig(
            image=shared_utils.docker_cache_image_calc(
                docker_cache_params,
                DEFAULT_QRL_METRICS_EXPORTER_IMAGE,
            ),
            ports={
                HTTP_PORT_ID: shared_utils.new_port_spec(
                    METRICS_PORT_NUMBER,
                    shared_utils.TCP_PROTOCOL,
                    shared_utils.HTTP_APPLICATION_PROTOCOL,
                )
            },
            cmd=[
                "--metrics-port",
                str(METRICS_PORT_NUMBER),
                "--consensus-url",
                "{0}".format(
                    cl_context.beacon_http_url,
                ),
                "--execution-url",
                "http://{}:{}".format(
                    el_context.ip_addr,
                    el_context.rpc_port_num,
                ),
            ],
            min_cpu=MIN_CPU,
            max_cpu=MAX_CPU,
            min_memory=MIN_MEMORY,
            max_memory=MAX_MEMORY,
            node_selectors=node_selectors,
        ),
    )

    return qrl_metrics_exporter_context.new_qrl_metrics_exporter_context(
        pair_name,
        exporter_service.ip_address,
        METRICS_PORT_NUMBER,
        cl_context.client_name,
        el_context.client_name,
    )
