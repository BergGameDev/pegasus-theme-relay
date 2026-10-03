import QtQuick 2.0
import SortFilterProxyModel 0.2

Item {
    id: root
    property int limit: 12
    property int sourceFilter: 0
    readonly property alias games: limited
    function gameAt(index) {
        if (index < 0 || index >= limited.count) return null;
        return sources.gameAt(sorted.mapToSource(limited.mapToSource(index)));
    }
    // Use the same separate source proxies as Library, then sort/limit the filtered view.
    LibraryModel { id: sources; sourceFilter: root.sourceFilter }
    SortFilterProxyModel {
        id: sorted
        sourceModel: sources.games
        filters: ExpressionFilter { expression: playCount > 0 || (lastPlayed && new Date(lastPlayed).getTime() > 0) }
        sorters: RoleSorter { roleName: "lastPlayed"; sortOrder: Qt.DescendingOrder }
    }
    SortFilterProxyModel {
        id: limited
        sourceModel: sorted
        filters: IndexFilter { maximumIndex: Math.min(root.limit, sorted.count) - 1 }
    }
}
