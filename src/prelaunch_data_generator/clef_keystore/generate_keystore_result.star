# Package object containing information about the keystore that was generated for clef
def new_generate_keystore_result(
    clef_key_password_artifact_uuid, clef_key_password_relative_filepath, keystore
):
    return struct(
        # Files artifact UUID where the Clef key password is stored
        clef_key_password_artifact_uuid=clef_key_password_artifact_uuid,
        # Relative to root of files artifact
        clef_key_password_relative_filepath=clef_key_password_relative_filepath,
        # Contains keystores-per-client-type for each node in the network
        keystore=keystore,
    )
