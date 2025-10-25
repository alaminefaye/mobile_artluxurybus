<?php

// ========================================
// ROUTES À AJOUTER DANS routes/api.php
// ========================================
// Copiez ces routes dans le groupe Route::middleware('auth:sanctum')
// après les routes bus existantes

// ===== VISITES TECHNIQUES =====
Route::post('buses/{bus}/technical-visits', [BusApiController::class, 'storeTechnicalVisit']);
Route::put('buses/{bus}/technical-visits/{visit}', [BusApiController::class, 'updateTechnicalVisit']);
Route::delete('buses/{bus}/technical-visits/{visit}', [BusApiController::class, 'destroyTechnicalVisit']);

// ===== ASSURANCES =====
Route::post('buses/{bus}/insurance-records', [BusApiController::class, 'storeInsurance']);
Route::put('buses/{bus}/insurance-records/{insurance}', [BusApiController::class, 'updateInsurance']);
Route::delete('buses/{bus}/insurance-records/{insurance}', [BusApiController::class, 'destroyInsurance']);

// ===== PANNES =====
// POST existe déjà (addBreakdown)
Route::put('buses/{bus}/breakdowns/{breakdown}', [BusApiController::class, 'updateBreakdown']);
Route::delete('buses/{bus}/breakdowns/{breakdown}', [BusApiController::class, 'destroyBreakdown']);

// ===== VIDANGES =====
// POST existe déjà (scheduleVidange)
Route::put('buses/{bus}/vidanges/{vidange}', [BusApiController::class, 'updateVidange']);
Route::delete('buses/{bus}/vidanges/{vidange}', [BusApiController::class, 'destroyVidange']);
