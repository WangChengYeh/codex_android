mod exec_command_params;
mod responses_api;
mod session_id;

#[cfg(target_os = "android")]
mod android_exec_command_session;
#[cfg(target_os = "android")]
mod android_session_manager;

#[cfg(not(target_os = "android"))]
mod exec_command_session;
#[cfg(not(target_os = "android"))]
mod session_manager;

pub use exec_command_params::ExecCommandParams;
pub use exec_command_params::WriteStdinParams;
pub use responses_api::EXEC_COMMAND_TOOL_NAME;
pub use responses_api::WRITE_STDIN_TOOL_NAME;
pub use responses_api::create_exec_command_tool_for_responses_api;
pub use responses_api::create_write_stdin_tool_for_responses_api;

#[cfg(target_os = "android")]
pub use android_session_manager::AndroidSessionManager as ExecSessionManager;
#[cfg(target_os = "android")]
pub use android_session_manager::result_into_payload;

#[cfg(not(target_os = "android"))]
pub use session_manager::SessionManager as ExecSessionManager;
#[cfg(not(target_os = "android"))]
pub use session_manager::result_into_payload;
