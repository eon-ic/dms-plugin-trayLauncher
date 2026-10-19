
import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root

    pluginId: "trayLauncher"

    StyledText {
        width: parent.width
        text: "Tray Launcher"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "搜索系统托盘应用，并通过桌面应用 ID 自动匹配名称和图标。"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StringSetting {
        settingKey: "trigger"
        label: "触发前缀"
        description: "输入此前缀打开托盘应用搜索"
        placeholder: "#"
        defaultValue: "#"
    }

    ListSettingWithInput {
        settingKey: "appIdMappings"
        label: "托盘 ID 与桌面应用映射"
        description: "支持托盘 ID 模糊匹配；精确匹配优先，较长的规则优先。"

        defaultValue: []

        fields: [
            {
                id: "id",
                label: "Tray ID",
                placeholder: "chrome_status_icon",
                width: 220,
                required: true
            },
            {
                id: "app_id",
                label: "Desktop App ID",
                placeholder: "org.telegram.desktop",
                width: 220,
                required: true
            }
        ]
    }

    StyledText {
        width: parent.width
        text: "配置示例"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "chrome_status_icon → org.telegram.desktop\ntelegram-tray → org.telegram.desktop\nqq_status → com.tencent.qq"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WrapAnywhere
    }

    StyledText {
        width: parent.width
        text: "搜索示例：#telegram 搜索名称、提示文本和应用 ID；#@sodam 只搜索包含 sodam 的托盘 ID。"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }
}

