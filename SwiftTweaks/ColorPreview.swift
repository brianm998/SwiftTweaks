import UIKit

class ColorPreview: UIView {
    /*
     This class exists as a replacement for a simple UIView that is used just
     to show a color with its backgroundColor property. 
     
     While that approach works fine in many cases, when used in a UITableViewCell
     the backgroundColor property is ignored when the cell is selected, causing the 
     view to disappear while it is still selected.

     Usage of this class will cause the desired color to remain visible during the
     selection of the UITableViewCell that contains it.
     */
    
    var color: UIColor = .clear {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        let path = UIBezierPath(rect: rect)

		var transparancy: CGFloat = 0
		color.getWhite(nil, alpha: &transparancy)

        // does our drawing color have any transparancy?
        if transparancy != 1 {
            // if so, then we need to draw something behind it first
            if let backgroundColor = superview?.backgroundColor {
                // use the super's background color if we can
                backgroundColor.setFill()
            } else {
                // default to a white background
                UIColor.white.setFill()
            }
            path.fill()
        }

        color.setFill()
        path.fill()
    }
}

