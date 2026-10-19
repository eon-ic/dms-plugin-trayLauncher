
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

QtObject {
    id: root

    property var pluginService: null
    property string trigger: "#"

    signal itemsChanged()

    // -------------------------
    // 初始化
    // -------------------------

    Component.onCompleted: {
        if (!pluginService)
            return

        const savedTrigger = pluginService.loadPluginData(
            "trayLauncher", "trigger", "#"
        )

        trigger = savedTrigger === null || savedTrigger === undefined
            ? "#"
            : String(savedTrigger)
    }

    // -------------------------
    // 托盘变化监听
    // -------------------------

    property Connections trayConnections: Connections {
        target: SystemTray.items

        function onRowsInserted() {
            root.itemsChanged()
        }

        function onRowsRemoved() {
            root.itemsChanged()
        }

        function onModelReset() {
            root.itemsChanged()
        }
    }

    // -------------------------
    // 工具函数
    // -------------------------

    function normalize(value) {
        return String(value ?? "").trim().toLowerCase()
    }

    function getTrayItems() {
        return SystemTray.items.values || []
    }
    function capitalizeFirst(str) {
        str = String(str || "")
        return str.charAt(0).toUpperCase() + str.slice(1)
    }
    function getMappings() {
        if (!pluginService)
            return []

        const mappings = pluginService.loadPluginData(
            "trayLauncher", "appIdMappings", []
        )

        return Array.isArray(mappings) ? mappings : []
    }

    // -------------------------
    // 模糊映射
    //
    // 普通规则：
    // exact > prefix > contains
    //
    // @规则：
    // @sodam 表示托盘 ID 包含 sodam
    //
    // 同级优先选择更长的匹配规则
    // -------------------------

    function matchMapping(trayId, mappings) {
        const id = normalize(trayId)

        if (!id)
            return null

        let bestMatch = null
        let bestPriority = 0
        let bestLength = 0

        for (const mapping of mappings) {
            if (!mapping || !mapping.id || !mapping.app_id)
                continue

            const rawPattern = String(mapping.id).trim()
            const isIdPattern = rawPattern.startsWith("@")

            const pattern = normalize(
                isIdPattern
                    ? rawPattern.substring(1)
                    : rawPattern
            )

            const appId = String(mapping.app_id).trim()

            if (!pattern || !appId)
                continue

            let priority = 0

            if (isIdPattern) {
                // @sodam：托盘 ID 包含 sodam
                if (id.includes(pattern))
                    priority = 2
            } else if (id === pattern) {
                priority = 4
            } else if (id.startsWith(pattern)) {
                priority = 3
            } else if (id.includes(pattern)) {
                priority = 2
            }

            // 不匹配就跳过，绝不使用最后一条规则作为默认值
            if (priority === 0)
                continue

            if (
                !bestMatch ||
                priority > bestPriority ||
                (
                    priority === bestPriority &&
                    pattern.length > bestLength
                )
            ) {
                bestMatch = {
                    id: rawPattern,
                    app_id: appId,
                    priority: priority
                }

                bestPriority = priority
                bestLength = pattern.length
            }
        }

        return bestMatch
    }

function resolveTrayItem(trayItem, mappings) {
    const id = capitalizeFirst(String(trayItem.id || ""))
    const title = String(
        trayItem.title || trayItem.tooltipTitle || id || "Unknown"
    )
    const tooltip = String(trayItem.tooltipDescription || "")

    const mapping = matchMapping(id, mappings)

    return {
        id: id,
        title: title,
        tooltip: tooltip,
        appId: mapping ? mapping.app_id : "",
        name: mapping ? mapping.app_id : title,
        icon: mapping ? mapping.app_id : id || trayItem.icon || "material:apps"
    }
}


    // -------------------------
    // 搜索
    // -------------------------

    function getItems(query) {
        const search = normalize(query)

        // @query：仅按托盘 ID 搜索
        const idOnly = search.startsWith("@")
        const keyword = idOnly
            ? search.substring(1)
            : search

        const trayItems = getTrayItems()
        const mappings = getMappings()
        const results = []

        for (const trayItem of trayItems) {
            if (!trayItem || trayItem.onlyMenu)
                continue
                
            const resolved = resolveTrayItem(
                trayItem,
                mappings
            )

            const normalizedId = normalize(resolved.id)

            if (idOnly) {
                if (
                    !keyword ||
                    !normalizedId.includes(keyword)
                ) {
                    continue
                }
            } else if (keyword) {
                const searchableText = normalize([
                    resolved.title,
                    resolved.id,
                    resolved.tooltip,
                    resolved.appId,
                    resolved.name
                ].join(" "))

                if (!searchableText.includes(keyword))
                    continue
            }

            results.push({
                name: capitalizeFirst(resolved.name),
                icon: resolved.icon,

                comment: resolved.appId
                    ? resolved.id + " → " + resolved.appId
                    : (
                        resolved.tooltip ||
                        "System Tray · " + resolved.id
                    ),

                categories: ["Tray Applications"],

                action: "activate:" +
                    encodeURIComponent(resolved.id)
            })
        }

        return results
    }

    // -------------------------
    // 执行
    // -------------------------

    function executeItem(item) {
        if (!item || !item.action)
            return

        const prefix = "activate:"

        if (!item.action.startsWith(prefix))
            return

        let id

        try {
            id = normalize(decodeURIComponent(
                item.action.substring(prefix.length)
            ))
        } catch (error) {
            console.warn(
                "[TrayLauncher] Invalid action:",
                item.action
            )
            return
        }

        // 重新查找最新的托盘对象
        const trayItem = getTrayItems().find(
            candidate =>
                candidate &&
                String(candidate.id || "") === id
        )

        if (!trayItem) {
            console.warn(
                "[TrayLauncher] Tray item no longer exists:",
                id
            )
            return
        }

        if (trayItem.onlyMenu) {
            console.warn(
                "[TrayLauncher] Tray item only has a menu:",
                id
            )
            return
        }

        trayItem.activate()
    }
}

