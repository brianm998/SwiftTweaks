
import UIKit


// The table cell that is used for editing colors when floating

internal final class FloatingColorTweakTableCell: UITableViewCell {

    // haven't gotten .automaticDimension working for this table cell
    // for now, the UITableViewDelegate needs to return this value from heightForRowAt:
    static let height: CGFloat = 130
    
    fileprivate let nameLabel = UILabel()

    // a holder view for the rgba sliders
    fileprivate let rgbaColorEditView = UIView()

    fileprivate let rgbaRNameLabel = UILabel()
    fileprivate let rgbaGNameLabel = UILabel()
    fileprivate let rgbaBNameLabel = UILabel()
    fileprivate let rgbaANameLabel = UILabel()

    fileprivate let rgbaRSlider = UISlider()
    fileprivate let rgbaGSlider = UISlider()
    fileprivate let rgbaBSlider = UISlider()
    fileprivate let rgbaASlider = UISlider()

    // a holder view for the hsba sliders
    fileprivate let hsbaColorEditView = UIView()

    fileprivate let hsbaHNameLabel = UILabel()
    fileprivate let hsbaSNameLabel = UILabel()
    fileprivate let hsbaBNameLabel = UILabel()
    fileprivate let hsbaANameLabel = UILabel()

    fileprivate let hsbaHSlider = UISlider()
    fileprivate let hsbaSSlider = UISlider()
    fileprivate let hsbaBSlider = UISlider()
    fileprivate let hsbaASlider = UISlider()

    // this holds the two (solid and with alpha) color previews
    fileprivate let colorPreviewHolder: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        return view
    }()
    
    fileprivate let colorPreviewSolidView = ColorPreview()
    fileprivate let colorPreviewAlphaView = ColorPreview()

    // used for the user to choose between rgba and hsba  
    fileprivate let segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: FloatingColorRepresentationType.titles)
        return control
    }()
    
    fileprivate var colorEditViews: [FloatingColorRepresentationType: UIView] = [:]

    fileprivate var viewData: FloatingColorRepresentation? {
        didSet {
            if let viewData = viewData {
                segmentedControl.selectedSegmentIndex = viewData.type.rawValue
                if let oldValue = oldValue,
                   oldValue.type != viewData.type
                {
                    self.segmentedControlChanged(segmentedControl)
                } else {
                    // no old data
                    for (key, value) in colorEditViews {
                        value.isHidden = key != viewData.type
                    }
                }

                updateSliders()

                // using background color here causes the selection of the table row
                // to make them dissapear :(
                colorPreviewSolidView.color = viewData.color.withAlphaComponent(1.0)
                colorPreviewAlphaView.color = viewData.color

                //colorPreviewSolidView.setNeedsDisplay()
                //colorPreviewAlphaView.setNeedsDisplay()
            }

            if let tweakStore = tweakStore,
               let viewData = viewData,
               let tweak = tweak
            {
                tweakStore.setValue(.color(value: viewData.color, defaultValue: tweak.defaultValue), forTweak: AnyTweak(tweak: tweak))
            }
            
        }
    }

    fileprivate var colorRepresentationType: FloatingColorRepresentationType? {
        set {
            if let oldViewData = viewData,
               let newValue = newValue
            {
                viewData = FloatingColorRepresentation(type: newValue, color: oldViewData.color)

                if let viewData = viewData {
                    for (key, value) in colorEditViews {
                        value.isHidden = key != viewData.type
                    }
                }
                updateSliders()
            }
        }
        get {
            return viewData?.type
        }
    }

    var anyTweak: AnyTweak? {
        set(newValue) {
            if let newValue = newValue,
               let tweak = newValue.tweak as? Tweak<UIColor>
            {
                self.tweak = tweak
            }
        }
        get { return nil }
    }
    
    var tweak: Tweak<UIColor>? {
        didSet {
            updateView()
        }
    }
    
    var tweakStore: TweakStore? {
        didSet {
            updateView()
        }
    }

    fileprivate func updateView() {
        if let tweak = tweak {
            self.nameLabel.text = tweak.tweakName
            if let tweakStore = tweakStore,
               let colorType = FloatingColorRepresentationType(rawValue: segmentedControl.selectedSegmentIndex)
            {
                self.viewData = FloatingColorRepresentation(type: colorType,
                                                            color: tweakStore.currentValueForTweak(tweak))
            }
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)

        let subviews = [segmentedControl, colorPreviewHolder, nameLabel]
        subviews.forEach { self.contentView.addSubview($0) }

        [colorPreviewSolidView, colorPreviewAlphaView].forEach {
            self.colorPreviewHolder.addSubview($0)
        }

        colorEditViews = 
          [
            .rgBa: rgbaColorEditView,
            .hsBa: hsbaColorEditView,
          ]
        
        colorEditViews.values.forEach  { self.contentView.addSubview($0) }
        
        [
          rgbaRNameLabel, rgbaGNameLabel, rgbaBNameLabel, rgbaANameLabel,
          rgbaRSlider, rgbaGSlider, rgbaBSlider, rgbaASlider
        ].forEach  { self.rgbaColorEditView.addSubview($0) }

        rgbaRSlider.tintColor = .red
        rgbaGSlider.tintColor = .green
        rgbaBSlider.tintColor = .blue
        rgbaASlider.tintColor = nil
        
        [
          rgbaRSlider, rgbaGSlider, rgbaBSlider, rgbaASlider,
          hsbaHSlider, hsbaSSlider, hsbaBSlider, hsbaASlider
        ].forEach {
            $0.minimumValue = 0
            $0.maximumValue = 1
            $0.addTarget(self,
                         action: #selector(self.sliderValueChanged(_:)),
                         for: .valueChanged)
        }
        
        rgbaRNameLabel.text = "R"
        rgbaGNameLabel.text = "G"
        rgbaBNameLabel.text = "B"
        rgbaANameLabel.text = "A"
        
        hsbaHSlider.tintColor = nil
        hsbaSSlider.tintColor = nil
        hsbaBSlider.tintColor = nil
        hsbaASlider.tintColor = nil
        
        [
          hsbaHNameLabel, hsbaSNameLabel, hsbaBNameLabel, hsbaANameLabel,
          hsbaHSlider, hsbaSSlider, hsbaBSlider, hsbaASlider
        ].forEach  { self.hsbaColorEditView.addSubview($0) }

        hsbaHNameLabel.text = "H"
        hsbaSNameLabel.text = "S"
        hsbaBNameLabel.text = "B"
        hsbaANameLabel.text = "A"
        
        colorEditViews[.rgBa]?.isHidden = true
        colorEditViews[.hsBa]?.isHidden = true

        segmentedControl.selectedSegmentIndex = 1
        segmentedControl.addTarget(self, action: #selector(self.segmentedControlChanged(_:)), for: .valueChanged)
    }

    fileprivate func updateSliders() {
        if let viewData = viewData {
            switch viewData {
            case .rgBa(let r, let g, let b, let a):
                rgbaRSlider.value = r.value / r.type.maximumValue
                rgbaGSlider.value = g.value / g.type.maximumValue
                rgbaBSlider.value = b.value / b.type.maximumValue
                rgbaASlider.value = a.value / a.type.maximumValue
                break
            case .hsBa(let h, let s, let b, let a):
                hsbaHSlider.value = h.value / h.type.maximumValue
                hsbaSSlider.value = s.value / s.type.maximumValue
                hsbaBSlider.value = b.value / b.type.maximumValue
                hsbaASlider.value = a.value / a.type.maximumValue
                break
            }
        }
    }
    
    @objc fileprivate func sliderValueChanged(_ sender: UISlider) {
        let rawValue = CGFloat(sender.value)
        if let viewData = viewData {
            switch viewData {
            case .rgBa(let r, let g, let b, let a):
                if sender == rgbaRSlider {
                    let newR = ColorComponentNumerical(type: .red, rawValue: rawValue)
                    self.viewData = .rgBa(r: newR, g: g, b: b, a: a)
                } else if sender == rgbaGSlider {
                    let newG = ColorComponentNumerical(type: .green, rawValue: rawValue)
                    self.viewData = .rgBa(r: r, g: newG, b: b, a: a)
                } else if sender == rgbaBSlider {
                    let newB = ColorComponentNumerical(type: .blue, rawValue: rawValue)
                    self.viewData = .rgBa(r: r, g: g, b: newB, a: a)
                } else if sender == rgbaASlider {
                    let newA = ColorComponentNumerical(type: .alpha, rawValue: rawValue)
                    self.viewData = .rgBa(r: r, g: g, b: b, a: newA)
                }
                
            case .hsBa(let h, let s, let b, let a):
                if sender == hsbaHSlider {
                    let newH = ColorComponentNumerical(type: .hue, rawValue: rawValue)
                    self.viewData = .hsBa(h: newH, s: s, b: b, a: a)
                } else if sender == hsbaSSlider {
                    let newS = ColorComponentNumerical(type: .saturation, rawValue: rawValue)
                    self.viewData = .hsBa(h: h, s: newS, b: b, a: a)
                } else if sender == hsbaBSlider {
                    let newB = ColorComponentNumerical(type: .brightness, rawValue: rawValue)
                    self.viewData = .hsBa(h: h, s: s, b: newB, a: a)
                } else if sender == hsbaASlider {
                    let newA = ColorComponentNumerical(type: .alpha, rawValue: rawValue)
                    self.viewData = .hsBa(h: h, s: s, b: b, a: newA)
                }
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        defer {
            // After adjusting the accessoryView's frame, we need to call super.layoutSubviews()
            super.layoutSubviews()
        }
        
        let contentFrame = self.contentView.frame

        nameLabel.frame = CGRect(origin: CGPoint(x: 15, y: 12),
                                 size: CGSize(width: 200, height: 20))

        // the origin of the two slider holder views
        let sliderHolderOrigin = CGPoint(x: 60, y: 45)

        // the width and height of the two slider holder views
        let colorEditWidth: CGFloat = contentFrame.size.width - sliderHolderOrigin.x - 10
        let colorEditHeight: CGFloat = contentFrame.size.height - sliderHolderOrigin.y - 10

        // the width of the segmented control
        let controlWidth: CGFloat = 140

        // each of the color previews are half of the height of the slider holder view
        let previewSize: CGFloat = colorEditHeight/2

        colorPreviewHolder.frame = CGRect(origin: CGPoint(x: 15, y: sliderHolderOrigin.y),
                                          size: CGSize(width: previewSize,
                                                       height: previewSize*2))

        let colorPreviewSize = CGSize(width: colorPreviewHolder.frame.size.width,
                                      height: colorPreviewHolder.frame.size.height/2)
        
        colorPreviewSolidView.frame = CGRect(origin: .zero, size: colorPreviewSize)

        colorPreviewAlphaView.frame = CGRect(origin: CGPoint(x: 0, y: colorPreviewSize.height),
                                             size: colorPreviewSize)
        
        segmentedControl.frame = CGRect(origin: CGPoint(x: contentFrame.size.width-controlWidth-10, y: 10),
                                        size: CGSize(width: controlWidth, height: 30))
        
        colorEditViews.values.forEach { view in
            view.frame = CGRect(origin: sliderHolderOrigin,
                                size: CGSize(width: colorEditWidth,
                                             height: colorEditHeight))
        }
 
        // rgba view
        perform2x2GridLayoutOn(sliders: ((rgbaRSlider, rgbaBSlider),
                                         (rgbaGSlider, rgbaASlider)),
                               withLabels: ((rgbaRNameLabel, rgbaBNameLabel),
                                           (rgbaGNameLabel, rgbaANameLabel)),
                               onView: rgbaColorEditView)
        // hsba view
        perform2x2GridLayoutOn(sliders: ((hsbaHSlider, hsbaBSlider),
                                         (hsbaSSlider, hsbaASlider)),
                               withLabels: ((hsbaHNameLabel, hsbaBNameLabel),
                                            (hsbaSNameLabel, hsbaANameLabel)),
                               onView: hsbaColorEditView)
   }

    fileprivate func perform2x2GridLayoutOn(sliders: ((UIView, UIView),
                                                      (UIView, UIView)),
                                            withLabels labels: ((UIView, UIView),
                                                                (UIView, UIView)),
                                            onView parentView: UIView)
    {
        // constants
        let padding: CGFloat = 5 // horizontal padding between the columns
        let nameLabelWidth: CGFloat = 15

        // computed values
        let rowHeight = parentView.frame.size.height/2
        let nameLabelSize = CGSize(width: nameLabelWidth, height: rowHeight)
        let sliderX = nameLabelSize.width
        let sliderWidth = (parentView.frame.size.width-padding)/2 - sliderX
        let sliderSize = CGSize(width: sliderWidth, height: rowHeight)
        let secondRowX = sliderX + sliderWidth + padding
 
        /*
         layout in a 2x2 grid:

         (0.0) (0.1)
         (1.0) (1.1)
        */
        labels.0.0.frame = CGRect(origin: .zero,
                                  size: nameLabelSize)
        labels.0.1.frame = CGRect(origin: CGPoint(x: secondRowX, y: 0),
                                  size: nameLabelSize)
        labels.1.0.frame = CGRect(origin: CGPoint(x: 0, y: rowHeight),
                                  size: nameLabelSize)
        labels.1.1.frame = CGRect(origin: CGPoint(x: secondRowX, y: rowHeight),
                                  size: nameLabelSize)

        sliders.0.0.frame = CGRect(origin: CGPoint(x: sliderX, y: 0),
                                   size: sliderSize)
        sliders.0.1.frame = CGRect(origin: CGPoint(x: sliderX + secondRowX, y: 0),
                                   size: sliderSize)
        sliders.1.0.frame = CGRect(origin: CGPoint(x: sliderX, y: rowHeight),
                                   size: sliderSize)
        sliders.1.1.frame = CGRect(origin: CGPoint(x: sliderX + secondRowX, y: rowHeight),
                                   size: sliderSize)
    }

    @objc fileprivate func segmentedControlChanged(_ sender: UISegmentedControl) {
        assert(sender == segmentedControl, "Unknown sender in segmentedControlChanged:")

        if let colorType = FloatingColorRepresentationType(rawValue: sender.selectedSegmentIndex) {
            colorRepresentationType = colorType
        }
    }
}

fileprivate enum FloatingColorRepresentationType: Int {
    case rgBa = 0
    case hsBa = 1

    static let titles: [String] = ["RGBa", "HSBa"]
}

fileprivate enum FloatingColorRepresentation {
    case rgBa(r: ColorComponentNumerical, g: ColorComponentNumerical, b: ColorComponentNumerical, a: ColorComponentNumerical)
    case hsBa(h: ColorComponentNumerical, s: ColorComponentNumerical, b: ColorComponentNumerical, a: ColorComponentNumerical)
}

extension FloatingColorRepresentation {
    fileprivate var type: FloatingColorRepresentationType {
        switch self {
        case .rgBa: return .rgBa
        case .hsBa: return .hsBa
        }
    }
    var color: UIColor {
        switch self {
        case let .rgBa(r: r, g: g, b: b, a: a):
            return UIColor(red: r.rawValue, green: g.rawValue, blue: b.rawValue, alpha: a.rawValue)
        case let .hsBa(h: h, s: s, b: b, a: a):
            return UIColor(hue: h.rawValue, saturation: s.rawValue, brightness: b.rawValue, alpha: a.rawValue)
        }
    }
    init(type: FloatingColorRepresentationType, color: UIColor) {
        switch type {
        case .rgBa:
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

            self = .rgBa(
                r: ColorComponentNumerical(type: .red, rawValue: red),
                g: ColorComponentNumerical(type: .green, rawValue: green),
                b: ColorComponentNumerical(type: .blue, rawValue: blue),
                a: ColorComponentNumerical(type: .alpha, rawValue: alpha)
            )
        case .hsBa:
            var hue: CGFloat = 0
            var saturation: CGFloat = 0
            var brightness: CGFloat = 0
            var alpha: CGFloat = 0
            color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

            self = .hsBa(
                h: ColorComponentNumerical(type: .hue, rawValue: hue),
                s: ColorComponentNumerical(type: .saturation, rawValue: saturation),
                b: ColorComponentNumerical(type: .brightness, rawValue: brightness),
                a: ColorComponentNumerical(type: .alpha, rawValue: alpha)
            )
        }
    }
}

