from fastapi import APIRouter, Query, Request

router = APIRouter(prefix="/api", tags=["risk_zone"])


@router.get("/risk-zone")
async def check_risk_zone(
    request: Request,
    lat: float = Query(..., description="Latitude pengguna"),
    lng: float = Query(..., description="Longitude pengguna"),
):
    """
    Cek apakah ada zona bahaya di dekat koordinat.
    Dipanggil Flutter saat Mode Navigasi aktif atau secara periodik.
    """
    svc     = request.app.state.risk_zone_service
    warning = svc.check_nearby(lat, lng)
    return {"risk_zone": warning}


@router.post("/risk-zone/report")
async def report_risk_zone(
    request: Request,
    lat:   float = Query(...),
    lng:   float = Query(...),
    label: str   = Query(..., description="Label objek yang terdeteksi"),
):
    """Manual report dari Flutter jika ada deteksi bahaya."""
    svc = request.app.state.risk_zone_service
    svc.report(lat, lng, label)
    return {"status": "reported"}
