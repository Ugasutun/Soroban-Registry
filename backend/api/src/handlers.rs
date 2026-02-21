use axum::{
    extract::State,
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use serde_json::{json, Value};

use crate::state::AppState;

pub type ApiResult<T> = Result<T, (StatusCode, String)>;

pub async fn health_check(State(state): State<AppState>) -> (StatusCode, Json<Value>) {
    let uptime = state.started_at.elapsed().as_secs();
    let now = chrono::Utc::now().to_rfc3339();

    let db_ok = sqlx::query_scalar::<_, i32>("SELECT 1")
        .fetch_one(&state.db)
        .await
        .is_ok();

    if db_ok {
        tracing::info!(uptime_secs = uptime, "health check passed");
        (StatusCode::OK, Json(json!({"status": "ok", "version": "0.1.0", "timestamp": now, "uptime_secs": uptime})))
    } else {
        (StatusCode::SERVICE_UNAVAILABLE, Json(json!({"status": "degraded", "version": "0.1.0", "timestamp": now, "uptime_secs": uptime})))
    }
}

pub async fn list_contracts() -> impl IntoResponse {
    Json(json!({"contracts": []}))
}

pub async fn get_contract() -> impl IntoResponse {
    Json(json!({"contract": null}))
}

pub async fn get_contract_abi() -> impl IntoResponse {
    Json(json!({"abi": null}))
}

pub async fn get_contract_versions() -> impl IntoResponse {
    Json(json!({"versions": []}))
}

pub async fn get_contract_state() -> impl IntoResponse {
    Json(json!({"state": {}}))
}

pub async fn update_contract_state() -> impl IntoResponse {
    Json(json!({"success": true}))
}

pub async fn get_contract_analytics() -> impl IntoResponse {
    Json(json!({"analytics": {}}))
}

pub async fn get_trust_score() -> impl IntoResponse {
    Json(json!({"score": 0}))
}

pub async fn get_contract_dependencies() -> impl IntoResponse {
    Json(json!({"dependencies": []}))
}

pub async fn get_contract_dependents() -> impl IntoResponse {
    Json(json!({"dependents": []}))
}

pub async fn get_contract_graph() -> impl IntoResponse {
    Json(json!({"graph": {}}))
}

pub async fn get_trending_contracts() -> impl IntoResponse {
    Json(json!({"trending": []}))
}

pub async fn publish_contract() -> impl IntoResponse {
    Json(json!({"success": true}))
}

pub async fn verify_contract() -> impl IntoResponse {
    Json(json!({"verified": true}))
}

pub async fn get_deployment_status() -> impl IntoResponse {
    Json(json!({"status": "pending"}))
}

pub async fn deploy_green() -> impl IntoResponse {
    Json(json!({"deployment_id": ""}))
}

pub async fn get_stats(State(state): State<AppState>) -> ApiResult<Json<Value>> {
    let total_contracts: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM contracts")
        .fetch_one(&state.db)
        .await
        .map_err(|_| (StatusCode::INTERNAL_SERVER_ERROR, "Database error".to_string()))?;

    Ok(Json(json!({"total_contracts": total_contracts, "verified_contracts": 0, "total_downloads": 0})))
}

pub async fn route_not_found() -> impl IntoResponse {
    (StatusCode::NOT_FOUND, Json(json!({"error": "Route not found"})))
}
