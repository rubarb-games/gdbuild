package models

Args :: struct {
    script_path: string `args:"name=script_path,pos=0" usage:"Path to the main script. Defaults to scripts/main.lua"`,
    live: bool          `args:"name=live"              usage:"A live run will bump the build number, archive the build and deploy to all target platforms."`,
    version: string     `args:"name=version"           usage:"Specify the version to set. If not specified, the last version will be used."`,
    verbose: bool       `args:"name=verbose"           usage:"Print all the details"`,
    build_type: string  `args:"name=build_type"        usage:"Common types: demo, full, dlc"`,
    build_mode: string  `args:"name=build_mode"        usage:"Common modes: dev, beta, release"`,
    
    // narrow down to one platform is useful when building locally to save time.
    // Can also be used to publish a patch for one specific target. In that case
    // the patched target will get a newer version than all the others. The version
    // will get back in sync with all the others upon the next build that targets 
    // all platforms.
    // Can pass a comma separated list of platforms(?)
    // platform: string - specify target platform. Danger! It will cause builds to get out of sync. Maybe it should demand a dry run? if out of sync builds are ok, then saving current version needs to specify platform
    platforms: string   `args:"name=platforms"         usage:"Comma separated list of platforms to build to."`,
}

Build :: struct {
    args: ^Args,
    version: ^Version,
    config: ^Config,
    targets: [dynamic]^BuildTarget,
}

BuildTarget :: struct {
    name: string,
    //project_settings: ^ProjectSettings,
    export_preset: ^ExportPreset,
    //preprocess function name? Call into lua
}

DeploymentTarget :: struct {
    //lua callback
    //...?
}

Config :: struct {
    version_repo: string, // rename to version_repo_url. Consider creating a
    // GitRepo struct for holding url, branch and commit hash. Could standardise
    // git workflow for all connected repos
    folder_project: string,
    folder_project_abs: string,
    godot_version: string,

    // - if no repo_branch is defined, default to "main"
    // - if commit is defined, first switch to branch, then checkout commit
    repo_url: string,
    repo_branch: string,
    repo_commit: string,

    // Path to the preprocessor script within the project folder
    // Preprocessing should happen outside the project.
    // Could be a lua function name instead. Moved to BuildTarget
    godot_preprocessor: string,
    
    build_type: string,
    build_mode: string,
}

Version :: struct {
    major: int,
    minor: int,
    build_num: int,
}

ExportFiles :: struct {
    name: string,
    values: [dynamic]string
}

CustomizedFiles :: struct {
    name: string,
    values: map[string]string
}

ExportResources :: union {
    ExportFiles,
    CustomizedFiles,
}

ExportPresets :: struct {
// [runnable_presets]
// Linux="Linux"
// "Windows Desktop"="Windows"
    runnable_presets: map[string]string,
    preset: [dynamic]^ExportPreset,
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
    runnable:              bool, // should probably always be true?
    dedicated_server:      bool,
    custom_features:       string,
    export_filter:         string,
    export_files:          [dynamic]string,
    include_filter:        string,
    exclude_filter:        string,
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
