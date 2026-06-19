from django.contrib.auth import get_user_model
from django.db.models.signals import post_save
from django.dispatch import receiver
from ..usuarios.models import PerfilUsuario
from ..pagos.models import Billetera


User = get_user_model()


@receiver(post_save, sender=User)
def crear_perfil_y_billetera(sender, instance, created, **kwargs):
    """
    Crea automáticamente el perfil de usuario y la billetera
    cuando se registra un nuevo usuario en el sistema.
    """

    if instance.is_superuser:
        rol = PerfilUsuario.Rol.ADMINISTRADOR
    elif instance.is_staff:
        rol = PerfilUsuario.Rol.OPERADOR
    else:
        rol = PerfilUsuario.Rol.USUARIO

    perfil, perfil_creado = PerfilUsuario.objects.get_or_create(
        usuario=instance,
        defaults={
            "rol": rol,
            "estado": True,
        }
    )

    if not perfil_creado:
        if instance.is_superuser and perfil.rol != PerfilUsuario.Rol.ADMINISTRADOR:
            perfil.rol = PerfilUsuario.Rol.ADMINISTRADOR
            perfil.save()

        elif instance.is_staff and perfil.rol != PerfilUsuario.Rol.OPERADOR:
            perfil.rol = PerfilUsuario.Rol.OPERADOR
            perfil.save()

    if rol == PerfilUsuario.Rol.USUARIO:
        Billetera.objects.get_or_create(
            usuario=instance,
            defaults={
                "saldo": 0.00,
                "estado": Billetera.Estado.ACTIVA,
            }
        )