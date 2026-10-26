package models

Args :: struct {
    script_path: string `args:"pos=0"          usage:"Path to the main script. Defaults to scripts/main.lua"`,
    dry: bool           `args:"name=dry"       usage:"A dry run will only build the application, and will not bump the version or build number, and will not distribute to any target platforms."`,
    version: string     `args:"name=version,v" usage:"Specify the version to set. If not specified, the last version will be used."`,
    verbose: bool       `args:"name=verbose"   usage:"Print all the details"`
    // platform: string - specify target platform. Danger! It will cause builds to get out of sync. Maybe it should demand a dry run? if out of sync builds are ok, then saving current version needs to specify platform
    // mode: string - dev, beta, release. defaults to dev
    // type: string - demo, full, dlc

    // flags can use bits, like this: platform=steam,gog,epic to specify a set of options
}

Config :: struct {
	version_repo: string,
	folder_project: string,
	godot_version: string,

	// - if no repo_branch is defined, default to "main"
	// - if commit is defined, first switch to branch, then checkout commit
	repo_url: string,
	repo_branch: string,
	repo_commit: string,

	// Path to the preprocessor script within the project folder
	godot_preprocessor: string,
}

ExportPresetOptions :: struct {
    custom_template_debug:              string,
    custom_template_release:            string,
    debug_export_console_wrapper:       int,
    binary_format_embed_pck:             bool,
    texture_format_s3tc_bptc:            bool,
    texture_format_etc2_astc:            bool,
    shader_baker_enabled:                bool,
    binary_format_architecture:          string,
    codesign_enable:                     bool,
    codesign_timestamp:                  bool,
    codesign_timestamp_server_url:       string,
    codesign_digest_algorithm:           int,
    codesign_description:                string,
    codesign_custom_options:             [dynamic]string,
    application_modify_resources:        bool,
    application_icon:                    string,
    application_console_wrapper_icon:    string,
    application_icon_interpolation:      int,
    application_file_version:            string,
    application_product_version:         string,
    application_company_name:            string,
    application_product_name:            string,
    application_file_description:        string,
    application_copyright:                string,
    application_trademarks:               string,
    application_export_angle:             int,
    application_export_d3d12:             int,
    application_d3d12_agility_sdk_multiarch: bool,
    ssh_remote_deploy_enabled:            bool,
    ssh_remote_deploy_host:               string,
    ssh_remote_deploy_port:               string,
    ssh_remote_deploy_extra_args_ssh:     string,
    ssh_remote_deploy_extra_args_scp:     string,
    ssh_remote_deploy_run_script:         string,
    ssh_remote_deploy_cleanup_script:     string,

    // some kind of dictionary for holding custom addon settings
    // sentry/asdf
    // imgui/debug=false etc
}

ExportPreset :: struct {
    name:                  string,
    platform:              string,
    runnable:              bool,
    dedicated_server:      bool,
    custom_features:       string,
    export_filter:         string,
    export_files:          [dynamic]string,
    include_filter:        string,
    exclude_filter:        string,
    export_path:           string,
    patches:               [dynamic]string,
    patch_delta_encoding:  bool,
    patch_delta_compression_level_zstd: int,
    patch_delta_min_reduction:          f64,
    patch_delta_include_filters:        string,
    patch_delta_exclude_filters:        string,
    encryption_include_filters:          string,
    encryption_exclude_filters:          string,
    seed:                   int,
    encrypt_pck:            bool,
    encrypt_directory:      bool,
    script_export_mode:     int,

    options: ^ExportPresetOptions,
}
