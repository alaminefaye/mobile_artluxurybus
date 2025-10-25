<?php

// ============================================
// MÉTHODES CORRIGÉES POUR LES PANNES
// À copier-coller dans BusApiController.php
// ============================================

/**
 * Ajouter une panne
 * POST /api/buses/{busId}/breakdowns
 */
public function storeBreakdown(Request $request, $busId)
{
    $validated = $request->validate([
        'reparation_effectuee' => 'required|string',
        'date_panne' => 'required|date',
        'description_probleme' => 'required|string',
        'diagnostic_mecanicien' => 'required|string',
        'statut_reparation' => 'required|in:en_cours,terminee,en_attente_pieces',
        'kilometrage' => 'nullable|integer',
        'piece_remplacee' => 'nullable|string',
        'prix_piece' => 'nullable|numeric',
        'facture_photo' => 'nullable|string',
        'notes_complementaires' => 'nullable|string',
    ]);

    $validated['bus_id'] = $busId;
    $validated['created_by'] = auth()->id();
    
    $breakdown = BusBreakdown::create($validated);

    return response()->json($breakdown, 201);
}

/**
 * Modifier une panne
 * PUT /api/buses/{busId}/breakdowns/{breakdownId}
 */
public function updateBreakdown(Request $request, $busId, $breakdownId)
{
    $breakdown = BusBreakdown::where('bus_id', $busId)
        ->findOrFail($breakdownId);

    $validated = $request->validate([
        'reparation_effectuee' => 'sometimes|required|string',
        'date_panne' => 'sometimes|required|date',
        'description_probleme' => 'sometimes|required|string',
        'diagnostic_mecanicien' => 'sometimes|required|string',
        'statut_reparation' => 'sometimes|required|in:en_cours,terminee,en_attente_pieces',
        'kilometrage' => 'nullable|integer',
        'piece_remplacee' => 'nullable|string',
        'prix_piece' => 'nullable|numeric',
        'facture_photo' => 'nullable|string',
        'notes_complementaires' => 'nullable|string',
    ]);

    $breakdown->update($validated);

    return response()->json($breakdown);
}

/**
 * Supprimer une panne
 * DELETE /api/buses/{busId}/breakdowns/{breakdownId}
 */
public function destroyBreakdown($busId, $breakdownId)
{
    $breakdown = BusBreakdown::where('bus_id', $busId)
        ->findOrFail($breakdownId);
    
    $breakdown->delete();

    return response()->json(['message' => 'Panne supprimée avec succès']);
}

/**
 * Liste des pannes d'un bus
 * GET /api/buses/{busId}/breakdowns
 */
public function getBreakdowns($busId)
{
    $breakdowns = BusBreakdown::where('bus_id', $busId)
        ->orderBy('date_panne', 'desc')
        ->get();

    return response()->json($breakdowns);
}
