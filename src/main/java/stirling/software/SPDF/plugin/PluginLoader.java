package stirling.software.SPDF.plugin;

import java.io.File;
import java.net.URL;
import java.net.URLClassLoader;
import java.util.ArrayList;
import java.util.List;

public class PluginLoader {

    private static final String PLUGIN_DIR = "config/plugins";

    public List<PluginInterface> loadPlugins() throws Exception {
        List<PluginInterface> plugins = new ArrayList<>();

        File pluginDir = new File(PLUGIN_DIR);
        File[] jarFiles = pluginDir.listFiles((dir, name) -> name.endsWith(".jar"));

        if (jarFiles != null) {
            for (File jarFile : jarFiles) {
                URL jarURL = jarFile.toURI().toURL();
                URLClassLoader classLoader =
                        new URLClassLoader(new URL[] {jarURL}, this.getClass().getClassLoader());

                // Hier musst du den Plugin-Klassennamen wissen
                Class<?> pluginClass = classLoader.loadClass("com.yourapp.plugins.MyPlugin");
                PluginInterface plugin =
                        (PluginInterface)
                                pluginClass
                                        .getDeclaredConstructor(String.class)
                                        .newInstance(PLUGIN_DIR);

                plugin.initialize();
                plugins.add(plugin);
            }
        }

        return plugins;
    }
}
