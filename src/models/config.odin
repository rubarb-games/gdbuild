package models

Config :: struct {
	folder_project: string,
	folder_output: string,

	godot_version: string,

	// - if no repo_branch is defined, default to "main"
	// - if commit is defined, first switch to branch, then checkout commit
	repo_branch: string,
	repo_commit: string,

	// Path to the preprocessor script within the project folder
	preprocessor: string,

	path_log_build: []string,
	path_log_preprocessor: []string,
	path_log_export: []string,
	path_log_deployment: []string,
}