//
//  FavoriteFlowLayout.swift
//  surf
//
//  Created by Allen Spicer on 7/19/18.
//  Copyright © 2018 surf. All rights reserved.
//

import UIKit

class FavoriteFlowLayout: UICollectionViewFlowLayout {
    var standardItemAlpha: CGFloat = 0.5
    var standardItemScale: CGFloat = 0.65
    var standardVerticalOffset: CGFloat = 100.0
    var screenHeightOffset: CGFloat =  0.6 * (UIScreen.main.bounds.size.height - 812)
    
    var isSetup = false
    
    override func prepare() {
        super.prepare()
        if isSetup == false {
            setupCollectionView()
            isSetup = true
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributesCopy = [UICollectionViewLayoutAttributes]()
        guard let attributes = super.layoutAttributesForElements(in: rect) else {return attributesCopy}
        for itemAttributes in attributes {
            if let itemAttributesCopy = itemAttributes.copy() as? UICollectionViewLayoutAttributes{
                changeLayoutAttributes(itemAttributesCopy)
                attributesCopy.append(itemAttributesCopy)
            }
        }
        
        return attributesCopy
    }
    
    override open func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    func changeLayoutAttributes(_ attributes: UICollectionViewLayoutAttributes) {
        guard let view = collectionView else {return}
        
        let collectionCenter = view.frame.size.width/2
        let offset = view.contentOffset.x
        let normalizedCenter = attributes.center.x - offset
        
        let maxDistance = self.itemSize.width + self.minimumInteritemSpacing
        let distance = min(abs(collectionCenter - normalizedCenter), maxDistance)
        let ratio = (maxDistance - distance)/maxDistance
        
        let alpha = ratio * (1 - self.standardItemAlpha) + self.standardItemAlpha
        let scale = ratio * (1 - self.standardItemScale) + self.standardItemScale
        attributes.alpha = alpha
        attributes.transform3D = CATransform3DScale(CATransform3DIdentity, scale, scale, 1)
        attributes.zIndex = Int(alpha * 10)
        attributes.center = CGPoint(x: attributes.center.x, y: (attributes.center.y + (standardVerticalOffset * ratio) + screenHeightOffset))
    }
    
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let view = collectionView else {return proposedContentOffset}
        guard let layoutAttributes = self.layoutAttributesForElements(in: view.bounds) else {return proposedContentOffset}
        let center = view.bounds.size.width / 2
        let proposedContentOffsetCenterOrigin = proposedContentOffset.x + center
        let closest = layoutAttributes.sorted { abs($0.center.x - proposedContentOffsetCenterOrigin) < abs($1.center.x - proposedContentOffsetCenterOrigin) }.first ?? UICollectionViewLayoutAttributes()
        let targetContentOffset = CGPoint(x: floor(closest.center.x - center), y: proposedContentOffset.y)
        return targetContentOffset
    }
    
    
    func setupCollectionView() {
        guard let view = collectionView else {return}
        view.decelerationRate = UIScrollView.DecelerationRate.fast
        let collectionSize = view.bounds.size
        let xInset = (collectionSize.width - self.itemSize.width) / 2
        self.sectionInset = UIEdgeInsets.init(top: 0, left: xInset, bottom: 0, right: xInset)
    }
    
}
