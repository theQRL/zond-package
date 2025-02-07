# Package object containing information about the keystores that were generated for validators
# during genesis creation
def new_generate_keystores_result(
    qrysm_password_artifact_uuid, qrysm_password_relative_filepath, per_node_keystores
):
    return struct(
        # Files artifact UUID where the Qrysm password is stored
        qrysm_password_artifact_uuid=qrysm_password_artifact_uuid,
        # Relative to root of files artifact
        qrysm_password_relative_filepath=qrysm_password_relative_filepath,
        # Contains keystores-per-client-type for each node in the network
        per_node_keystores=per_node_keystores,
    )
