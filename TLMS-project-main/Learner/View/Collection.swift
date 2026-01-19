//
//
//  TLMS-project-main
//
//  Created by Chehak on 19/01/26.
//

import Foundation

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

