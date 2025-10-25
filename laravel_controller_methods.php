<?php

// ========================================
// MÉTHODES À AJOUTER DANS BusApiController.php
// ========================================
// Copiez ces méthodes à la fin de la classe BusApiController
// (avant la dernière accolade fermante)

// ===== VISITES TECHNIQUES =====

/**
 * Créer une visite technique
 */
public function storeTechnicalVisit(Request $request, $busId)
{
    $validated = $request->validate([
        'visit_date' => 'required|date',
        'expiry_date' => 'required|date|after:visit_date',
        'result' => 'required|string|in:Favorable,Défavorable',
        'visit_center' => 'nullable|string|max:255',
        'cost' => 'nullable|numeric|min:0',
        'certificate_number' => 'nullable|string|max:100',
        'notes' => 'nullable|string',
    ]);

    $visit = \App\Models\TechnicalVisit::create([
        'bus_id' => $busId,
        ...$validated,
    ]);

    return response()->json($visit, 201);
}

/**
 * Modifier une visite technique
 */
public function updateTechnicalVisit(Request $request, $busId, $visitId)
{
    $visit = \App\Models\TechnicalVisit::where('bus_id', $busId)->findOrFail($visitId);
    
    $validated = $request->validate([
        'visit_date' => 'required|date',
        'expiry_date' => 'required|date|after:visit_date',
        'result' => 'required|string|in:Favorable,Défavorable',
        'visit_center' => 'nullable|string|max:255',
        'cost' => 'nullable|numeric|min:0',
        'certificate_number' => 'nullable|string|max:100',
        'notes' => 'nullable|string',
    ]);

    $visit->update($validated);

    return response()->json($visit);
}

/**
 * Supprimer une visite technique
 */
public function destroyTechnicalVisit($busId, $visitId)
{
    $visit = \App\Models\TechnicalVisit::where('bus_id', $busId)->findOrFail($visitId);
    $visit->delete();

    return response()->json(['message' => 'Visite technique supprimée avec succès'], 200);
}

// ===== ASSURANCES =====

/**
 * Créer une assurance
 */
public function storeInsurance(Request $request, $busId)
{
    $validated = $request->validate([
        'insurance_company' => 'required|string|max:255',
        'policy_number' => 'required|string|max:100',
        'start_date' => 'required|date',
        'expiry_date' => 'required|date|after:start_date',
        'coverage_type' => 'required|string|max:100',
        'premium' => 'required|numeric|min:0',
        'notes' => 'nullable|string',
    ]);

    $insurance = \App\Models\InsuranceRecord::create([
        'bus_id' => $busId,
        ...$validated,
    ]);

    return response()->json($insurance, 201);
}

/**
 * Modifier une assurance
 */
public function updateInsurance(Request $request, $busId, $insuranceId)
{
    $insurance = \App\Models\InsuranceRecord::where('bus_id', $busId)->findOrFail($insuranceId);
    
    $validated = $request->validate([
        'insurance_company' => 'required|string|max:255',
        'policy_number' => 'required|string|max:100',
        'start_date' => 'required|date',
        'expiry_date' => 'required|date|after:start_date',
        'coverage_type' => 'required|string|max:100',
        'premium' => 'required|numeric|min:0',
        'notes' => 'nullable|string',
    ]);

    $insurance->update($validated);

    return response()->json($insurance);
}

/**
 * Supprimer une assurance
 */
public function destroyInsurance($busId, $insuranceId)
{
    $insurance = \App\Models\InsuranceRecord::where('bus_id', $busId)->findOrFail($insuranceId);
    $insurance->delete();

    return response()->json(['message' => 'Assurance supprimée avec succès'], 200);
}

// ===== PANNES =====

/**
 * Modifier une panne
 */
public function updateBreakdown(Request $request, $busId, $breakdownId)
{
    $breakdown = \App\Models\BusBreakdown::where('bus_id', $busId)->findOrFail($breakdownId);
    
    $validated = $request->validate([
        'description' => 'required|string',
        'breakdown_date' => 'required|date',
        'severity' => 'required|string|in:low,medium,high',
        'status' => 'required|string|in:reported,in_progress,resolved',
        'repair_cost' => 'nullable|numeric|min:0',
        'resolved_date' => 'nullable|date|after_or_equal:breakdown_date',
        'notes' => 'nullable|string',
    ]);

    $breakdown->update($validated);

    return response()->json($breakdown);
}

/**
 * Supprimer une panne
 */
public function destroyBreakdown($busId, $breakdownId)
{
    $breakdown = \App\Models\BusBreakdown::where('bus_id', $busId)->findOrFail($breakdownId);
    $breakdown->delete();

    return response()->json(['message' => 'Panne supprimée avec succès'], 200);
}

// ===== VIDANGES =====

/**
 * Modifier une vidange
 */
public function updateVidange(Request $request, $busId, $vidangeId)
{
    $vidange = \App\Models\BusVidange::where('bus_id', $busId)->findOrFail($vidangeId);
    
    $validated = $request->validate([
        'type' => 'required|string|max:100',
        'vidange_date' => 'nullable|date',
        'next_vidange_date' => 'nullable|date',
        'planned_date' => 'nullable|date',
        'cost' => 'nullable|numeric|min:0',
        'service_provider' => 'nullable|string|max:255',
        'mileage' => 'nullable|numeric|min:0',
        'notes' => 'nullable|string',
    ]);

    $vidange->update($validated);

    return response()->json($vidange);
}

/**
 * Supprimer une vidange
 */
public function destroyVidange($busId, $vidangeId)
{
    $vidange = \App\Models\BusVidange::where('bus_id', $busId)->findOrFail($vidangeId);
    $vidange->delete();

    return response()->json(['message' => 'Vidange supprimée avec succès'], 200);
}
