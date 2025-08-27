use serde::{Deserialize, Serialize};
use std::env;
use std::fs;

#[derive(Serialize, Deserialize)]
struct TestData {
    message: String,
    args: Vec<String>,
    current_dir: String,
    env_vars: Vec<(String, String)>,
}

fn main() {
    println!("=== Android Rust Test Application ===");
    
    let args: Vec<String> = env::args().collect();
    let current_dir = env::current_dir()
        .map(|p| p.display().to_string())
        .unwrap_or_else(|_| "Unable to get current directory".to_string());
    
    let mut env_vars: Vec<(String, String)> = Vec::new();
    for (key, value) in env::vars() {
        if key.starts_with("ANDROID") || key.contains("PATH") || key.contains("HOME") {
            env_vars.push((key, value));
        }
    }
    
    let test_data = TestData {
        message: "Hello from Android Rust!".to_string(),
        args,
        current_dir,
        env_vars,
    };
    
    println!("Current directory: {}", test_data.current_dir);
    println!("Arguments: {:?}", test_data.args);
    println!("Relevant environment variables:");
    for (key, value) in &test_data.env_vars {
        println!("  {}={}", key, value);
    }
    
    // Try to write some test data
    match serde_json::to_string_pretty(&test_data) {
        Ok(json_str) => {
            println!("JSON representation:");
            println!("{}", json_str);
            
            // Try to write to a file
            let file_path = "/data/local/tmp/android_test_output.json";
            match fs::write(file_path, json_str) {
                Ok(_) => println!("Successfully wrote test data to {}", file_path),
                Err(e) => println!("Failed to write to file: {}", e),
            }
        }
        Err(e) => println!("Failed to serialize data: {}", e),
    }
    
    println!("Test completed successfully!");
}