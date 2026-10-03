import QtQuick 2.0
import SortFilterProxyModel 0.2

Item {
    id: root
    property int sourceFilter: 0
    readonly property alias games: proxy
    function gameAt(index) {
        if (index < 0 || index >= proxy.count) return null;
        return sources.gameAt(proxy.mapToSource(index));
    }
    LibraryModel { id: sources; sourceFilter: root.sourceFilter }
    SortFilterProxyModel {
        id: proxy
        sourceModel: sources.games
        filters: ValueFilter { roleName: "favorite"; value: true }
        sorters: RoleSorter { roleName: "lastPlayed"; sortOrder: Qt.DescendingOrder }
    }
}
