﻿using Wox.Core.Utils;
using Wox.Plugin;

namespace Wox.Core.Plugin;

/// <summary>
///     The entry for managing Wox plugins
/// </summary>
public static class PluginManager
{
    private static List<PluginInstance> _pluginInstances = new();

    public static List<PluginInstance> GetAllPlugins()
    {
        return _pluginInstances;
    }


    public static void LoadPlugins(IPublicAPI api)
    {
        _pluginInstances = PluginLoader.LoadPlugins();
        InitPlugins(api);
    }

    private static void UnloadPlugin(PluginInstance plugin, string reason)
    {
        Logger.Info($"Plugin {plugin.Metadata.Name} was unloaded because {reason}");
        _pluginInstances.Remove(plugin);
    }

    private static void InitPlugins(IPublicAPI api)
    {
        Parallel.ForEach(_pluginInstances, pluginInstance =>
        {
            try
            {
                Logger.Debug($"Start to init plugin {pluginInstance.Metadata.Name}");
                var startTime = DateTime.Now;
                pluginInstance.Plugin.Init(new PluginInitContext(api));
                // pluginInstance.Metadata.InitTime += DateTime.Now.Subtract(startTime).Milliseconds;
                // Logger.Info($"init plugin {pluginInstance.Metadata.Name} success, total init cost is {pluginInstance.Metadata.InitTime}ms");
            }
            catch (Exception e)
            {
                e.Data.Add(nameof(pluginInstance.Metadata.Id), pluginInstance.Metadata.Id);
                e.Data.Add(nameof(pluginInstance.Metadata.Name), pluginInstance.Metadata.Name);
                e.Data.Add(nameof(pluginInstance.Metadata.Website), pluginInstance.Metadata.Website);
                Logger.Error($"Fail to init plugin: {pluginInstance.Metadata.Name}", e);
                UnloadPlugin(pluginInstance, "failed to init");
                //TODO: need someway to nicely tell user this plugin failed to load
            }
        });
    }

    public static List<PluginQueryResult> QueryForPlugin(PluginInstance plugin, Query query)
    {
        if (plugin.CommonSetting.Disabled) return new List<PluginQueryResult>();

        var validGlobalQuery = string.IsNullOrEmpty(query.TriggerKeyword);
        var validNonGlobalQuery = plugin.Metadata.TriggerKeywords.Contains(query.TriggerKeyword ?? string.Empty);
        if (!validGlobalQuery && !validNonGlobalQuery) return new List<PluginQueryResult>();

        try
        {
            var results = plugin.Plugin.Query(query);
            return results.Select(r => new PluginQueryResult
            {
                Result = r,
                AssociatedQuery = query,
                Plugin = plugin
            }).ToList();
        }
        catch (Exception e)
        {
            Logger.Error($"plugin {plugin.Metadata.Name} query ({query}) failed:", e);
            return new List<PluginQueryResult>();
        }
    }
}