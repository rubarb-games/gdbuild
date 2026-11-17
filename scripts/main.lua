local c = require("scripts/common")

-- ATM, create_config works one single config. A future version could
-- support writing multiple configs. By giving each one a unique id,
-- the could be created on the odin side.
-- set_folder_project(0, "...")

-- One config per build. Multiple deployments
-- TODO: Should also provide a cur_version that collects all info about
-- the current version. That makes it easier to compare.
function create_config(args)
	--[[
	to support creating multiple configs:
	id = create_build()
	version_repo(id, "git@...")
	
	a build could be a struct that holds everything related to a build,
	also temporary vars

	create_export_preset() would be called once per config, and get the build id passed
	as first argument

	if any of the config functions are called without a build id, a
	build will be automatically created. Functions called after
	will use that build
	]]--

	version_repo("git@github.com:rubarb-games/basalt-01-version.git")
	project_folder("project")
	-- After the Godot version has been set, the export templates will be downloaded
	godot_version("4.6.1-stable")
	project_repo_url("git@github.com:rubarb-games/basalt-01.git")
	godot_preprocessor("build-script/preprocess.gd")

	-- Must set type and mode here
	build_type("demo") -- full, playtest
	-- as long as only buildnum changes, stay on dev
	-- when path, minor or major changes, use beta
	-- explicitly set release?
	build_mode("release") -- dev, beta, release

	-- already here decide where to deploy? or deploy at all?
end

function project_settings()
end

function create_export_preset(args, config, version)
	name("Thomas's Super Game")
	
	-- build_type = get_build_type()
	-- export_template(build_type, "folder/template_{build_type}")
	export_template("debug", "file://...")
	export_template("release", "file://...")

	-- Unless the custom_template settings have been set, the 
	-- platform function should verify that the export template
	-- exists.
	platform("Linux")

	-- export everything
	-- export_all()

	-- exclude certain directories and files
	-- exclude({
	-- 	"dev_tools",
	-- 	"temp",
	-- 	"scripts/in-use.gd"
	-- })

	-- only export the specified scenes and all its dependencies
	-- export_scenes({
	-- 	"scenes/main.tscn"
	-- })

	-- only export the specified resources and all its dependencies
	-- export_resources({
	-- 	"assets/weird.glsl"
	-- })

	-- include non-resources by wildcard
	include_filter({
		"*.toml",
		"*.ini"
	})

	-- exclude files and folders from export
	exclude_filter({
		"*.secret",
		"dev_tools"
	})

	-- script_export_mode("text") -- binary_token, compressed_binary_token
	-- binary_format_architecture??
	-- embed_pck(false)
	-- console_wrapper(false)

	-- texture_format_s3tc_bptc(true)
	-- texture_format_etc2_astc(false)
	-- shader_baker(true)

	-- These ones seem to only apply to windows builds. Maybe also mac?
	-- application_icon("") -- res:// ?
	-- application_file_version(version.full_string)
	-- app_icon_interpolation
	-- app_product_version
	-- app_company_name
	-- app_product_name
	-- app_file_description
	-- app_copyright
	-- app_export_angle?
	-- app_export_d3d12? agility_multiarch?
end
