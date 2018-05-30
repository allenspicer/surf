//
//  SurfSnapshotCollectionView.swift
//  surf
//
//  Created by uBack on 5/30/18.
//  Copyright © 2018 surf. All rights reserved.
//

import UIKit

class SurfSnapshotCollectionView: UICollectionView {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: 100)
    }


}
