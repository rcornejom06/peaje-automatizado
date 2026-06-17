from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path

from drf_spectacular.views import (
    SpectacularAPIView,
    SpectacularSwaggerView,
)

from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)


urlpatterns = [
    path("admin/", admin.site.urls),

    # Auth JWT
    path("api/auth/token/", TokenObtainPairView.as_view(), name="token_obtain_pair"),
    path("api/auth/token/refresh/", TokenRefreshView.as_view(), name="token_refresh"),

    # Swagger / OpenAPI
    path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
    path(
        "api/docs/",
        SpectacularSwaggerView.as_view(url_name="schema"),
        name="swagger-ui",
    ),

    # Apps
    path("api/usuarios/", include("apps.usuarios.urls")),
    path("api/vehiculos/", include("apps.vehiculos.urls")),
    path("api/peajes/", include("apps.peajes.urls")),
    path("api/pagos/", include("apps.pagos.urls")),
    path("api/membresias/", include("apps.membresias.urls")),
    path("api/seguridad/", include("apps.seguridad.urls")),
    path("api/notificaciones/", include("apps.notificaciones.urls")),
    path("api/auditoria/", include("apps.auditoria.urls")),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)