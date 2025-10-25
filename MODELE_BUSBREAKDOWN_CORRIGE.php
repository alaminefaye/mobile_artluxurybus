<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class BusBreakdown extends Model
{
    use HasFactory;

    protected $fillable = [
        'bus_id',
        'kilometrage',
        'reparation_effectuee',
        'date_panne',
        'description_probleme',
        'diagnostic_mecanicien',
        'piece_remplacee',
        'prix_piece',
        'facture_photo',
        'notes_complementaires',
        'statut_reparation',
        'created_by',
    ];

    protected $casts = [
        'date_panne' => 'date',
        'prix_piece' => 'decimal:2',
        'kilometrage' => 'integer',
    ];

    /**
     * Relation avec le bus
     */
    public function bus()
    {
        return $this->belongsTo(Bus::class);
    }

    /**
     * Relation avec l'utilisateur qui a créé la panne
     */
    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
