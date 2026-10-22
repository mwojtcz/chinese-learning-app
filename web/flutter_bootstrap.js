{{flutter_js}}
{{flutter_build_config}}

function showLaunchError() {
  const status = document.getElementById('launch-status');
  if (status) {
    status.textContent = 'Nie udało się uruchomić aplikacji. Sprawdź połączenie i spróbuj ponownie.';
    document.getElementById('launch-retry').hidden = false;
  }
}

_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    try {
      const appRunner = await engineInitializer.initializeEngine();
      await appRunner.runApp();
      document.getElementById('launch')?.remove();
    } catch (error) {
      showLaunchError();
      console.error('Application startup failed.', error);
    }
  }
}).catch(showLaunchError);
