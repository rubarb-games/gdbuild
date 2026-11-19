local c = require("scripts/common")

-- One config -> multiple build targets -> multiple deployments
function build_config(args)
	-- Version from previous build is not accessible at this point.
	-- For any custom versioning, use the update_version callback

	-- enable option to turn off version repo. Or just not set a repo.
	-- that will enable a pipeline to simply use the version string passed
	-- via args.
	version_repo("git@github.com:rubarb-games/basalt-01-version.git")
	-- maybe expose some simple git functions to lua, to not embed
	-- the version repo feature?

	project_folder("project")
	-- After the Godot version has been set, the export templates will be downloaded
	godot_version("4.6.1-stable")
	project_repo_url("git@github.com:rubarb-games/basalt-01.git")
	godot_preprocessor("build-script/preprocess.gd")

	-- print("build mode: " .. args.build_mode .. "!?")


	-- Enable archiving of builds
	-- Default behaviour could be to make a local copy. In some cases, that might be
	-- just fine. Other backup services could pick up the archive and take a backup.
	-- For any other custom archiving options, a lua script plugin could be the
	-- solution. One entry point, where you can zip, upload and do whatever.
	-- When archive == true, look for lua callback. If no lua callback, default backup.
	-- archive(true/false)

	-- type and mode are passed via args.
	-- In this case, we default to a full dev build unless type and mode
	-- was set in args.
	-- if args.build_type == "" then
	-- 	build_type("full")
	-- end
	-- if args.build_mode == "" then
	-- 	build_type("dev")
	-- end

	-- If no platform was passed with args, set defaults
	-- if num_platforms() == 0 then
	-- 	--platform("win")
	-- 	platforms({ "win", "linux", "mac", "steamdeck" })
	-- end

	-- Decide which build gets distributed where
	-- deploy("win", { "steam", "epic", "winstore" })
	-- deploy("mac", { "steam", "epic", "macstore" })
	-- deploy("linux", { "steam", "epic" })
	-- deploy("steamdeck", { "steam" })

	-- If this pipeline was running on one mac machine, and one Linux machine,
	-- mac would build the 3 mac editions
	-- linux would build 3 for windows, 2 for linux and 1 for steamdeck

end

function update_version(cur_version)
	-- read current from cur_version
	-- write via api
	-- if this function does not exist, pipeline defaults to bumping the buildnum only
	-- if this function exists, pipeline interprets that as you wanting to take
	-- control over versioning. The function can still do nothing, which would cause
	-- the last version and current version to be the same. We don't want that.
	-- Therefore, the pipeline will compare the previous and the updated version,
	-- and stop if they haven't changed.
end

-- Will run once per build
-- Before calling this function, create an instance of project settings.
-- That way, the api for this function won't have to pass extra params.
function project_settings(args, version, config)
end

function export_preset(args, version, config, platform)
	local _name = ("%s %s %s"):format(platform, args.build_type, args.build_mode)
	print(_name)
	name(_name)
	
	-- export everything
	export_all()

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
	-- include_filter({
	-- 	"*.toml",
	-- 	"*.ini"
	-- })

	-- exclude files and folders from export
	-- exclude_filter({
	-- 	"*.secret",
	-- 	"dev_tools"
	-- })

	script_export_mode("text") -- binary_token, compressed_binary_token
	-- binary_format_architecture??
	-- embed_pck(false)
	export_console_wrapper("no") -- "debug_only", "debug_and_release"

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
