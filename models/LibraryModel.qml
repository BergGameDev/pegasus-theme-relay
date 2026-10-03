import QtQuick 2.0
import SortFilterProxyModel 0.2

Item {
    id: root
    // 0 = ALL, 1 = LOCAL/non-Steam, 2 = STEAM
    property int sourceFilter: 0
    readonly property var games: sourceFilter === 1 ? localProxy : (sourceFilter === 2 ? steamProxy : allProxy)

    function gameAt(index) {
        var p = games;
        if (!p || index < 0 || index >= p.count) return null;
        return api.allGames.get(p.mapToSource(index));
    }

    // Separate proxy instances are intentional. Changing the expression of one
    // live proxy left ListView with stale LOCAL/STEAM rows on some Pegasus builds.
    SortFilterProxyModel {
        id: allProxy
        sourceModel: api.allGames
    }

    SortFilterProxyModel {
        id: localProxy
        sourceModel: api.allGames
        filters: ExpressionFilter {
            expression: {
                var isSteam = false;
                for (var i = 0; i < collections.count; ++i) {
                    if (collections.get(i).name.toLowerCase() === "steam") {
                        isSteam = true;
                        break;
                    }
                }
                return !isSteam;
            }
        }
    }

    SortFilterProxyModel {
        id: steamProxy
        sourceModel: api.allGames
        filters: ExpressionFilter {
            expression: {
                for (var i = 0; i < collections.count; ++i) {
                    if (collections.get(i).name.toLowerCase() === "steam") return true;
                }
                return false;
            }
        }
    }
}
