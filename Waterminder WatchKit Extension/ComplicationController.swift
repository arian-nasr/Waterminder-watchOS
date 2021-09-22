//
//  ComplicationController.swift
//  Waterminder WatchKit Extension
//
//  Created by Arian Nasr on 2021-09-21.
//

import ClockKit


class ComplicationController: NSObject, CLKComplicationDataSource {
    
    lazy var data = WaterData.shared
    
    // MARK: - Complication Configuration

    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(identifier: "complication", displayName: "Waterminder", supportedFamilies: CLKComplicationFamily.allCases)
            // Multiple complication support can be added here with more descriptors
        ]
        
        // Call the handler with the currently supported complication descriptors
        handler(descriptors)
    }
    
    func handleSharedComplicationDescriptors(_ complicationDescriptors: [CLKComplicationDescriptor]) {
        // Do any necessary work to support these newly shared complication descriptors
    }

    // MARK: - Timeline Configuration
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        // Call the handler with the last entry date you can currently provide or nil if you can't support future timelines
        handler(nil)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        // Call the handler with your desired behavior when the device is locked
        handler(.showOnLockScreen)
    }

    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        // Call the handler with the current timeline entry
        handler(createTimelineEntry(forComplication: complication, date: Date()))
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries after the given date
        var entries = [CLKComplicationTimelineEntry]()
        entries.append(createTimelineEntry(forComplication: complication, date: date))
        handler(entries)
    }

    // MARK: - Sample Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
        let future = Date().addingTimeInterval(25.0 * 60.0 * 60.0)
        let template = createTemplate(forComplication: complication, date: future)
        handler(template)
    }
    
    private func createTimelineEntry(forComplication complication: CLKComplication, date: Date) ->
        CLKComplicationTimelineEntry {
        
            let template = createTemplate(forComplication: complication, date: date)
            return CLKComplicationTimelineEntry(date: date, complicationTemplate: template)
    }
    
    private func createTemplate(forComplication complication: CLKComplication, date: Date) -> CLKComplicationTemplate {
        switch complication.family {
        case .modularSmall:
            return createModularSmallTemplate(forDate: date)
        case .modularLarge:
            return createModularLargeTemplate(forDate: date)
        case .utilitarianSmall, .utilitarianSmallFlat:
            return createUtilitarianSmallFlatTemplate(forDate: date)
        case .utilitarianLarge:
            return createUtilitarianLargeTemplate(forDate: date)
        case .circularSmall:
            return createCircularSmallTemplate(forDate: date)
        case .extraLarge:
            return createExtraLargeTemplate(forDate: date)
        case .graphicCorner:
            return createGraphicCornerTemplate(forDate: date)
        case .graphicCircular:
            return createGraphicCircleTemplate(forDate: date)
        case .graphicRectangular:
            return createGraphicRectangularTemplate(forDate: date)
        case .graphicBezel:
            return createGraphicBezelTemplate(forDate: date)
        case .graphicExtraLarge:
            if #available(watchOSApplicationExtension 7.0, *) {
                return createGraphicExtraLargeTemplate(forDate: date)
            } else {
                fatalError("Graphic Extra Large template is only available on watchOS 7.")
            }
        @unknown default:
            fatalError("*** Unknown Complication Family ***")
        }
    }
    
    private func createModularSmallTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let mlWaterProvider = CLKSimpleTextProvider(text: String(data.mlWater(atDate: date)))
        let mlUnitProvider = CLKSimpleTextProvider(text: "mL Water", shortText: "mL")
        
        // Create the template using the providers.
        return CLKComplicationTemplateModularSmallStackText(line1TextProvider: mlWaterProvider,
                                                            line2TextProvider: mlUnitProvider)
    }
    
    // Return a modular large template.
    private func createModularLargeTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let titleTextProvider = CLKSimpleTextProvider(text: "Water Tracker", shortText: "Water")

        let mgCaffeineProvider = CLKSimpleTextProvider(text: String(data.mlWater(atDate: date)))
        let mgUnitProvider = CLKSimpleTextProvider(text: "mL Water", shortText: "mL")
        let combinedMGProvider = CLKTextProvider(format: "%@ %@", mgCaffeineProvider, mgUnitProvider)
               
        let numberOfCupsProvider = CLKSimpleTextProvider(text: String(data.totalCupsToday))
        let cupsUnitProvider = CLKSimpleTextProvider(text: "Cups", shortText: "C")
        let combinedCupsProvider = CLKTextProvider(format: "%@ %@", numberOfCupsProvider, cupsUnitProvider)
        
        // Create the template using the providers.
        let imageProvider = CLKImageProvider(onePieceImage: #imageLiteral(resourceName: "CoffeeModularLarge"))
        return CLKComplicationTemplateModularLargeStandardBody(headerImageProvider: imageProvider,
                                                               headerTextProvider: titleTextProvider,
                                                               body1TextProvider: combinedCupsProvider,
                                                               body2TextProvider: combinedMGProvider)
    }
    
    // Return a utilitarian small flat template.
    private func createUtilitarianSmallFlatTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let flatUtilitarianImageProvider = CLKImageProvider(onePieceImage: #imageLiteral(resourceName: "CoffeeSmallFlat"))
        
        let mgCaffeineProvider = CLKSimpleTextProvider(text: String(data.mlWater(atDate: date)))
        let mgUnitProvider = CLKSimpleTextProvider(text: "mL Water", shortText: "mL")
        let combinedMGProvider = CLKTextProvider(format: "%@ %@", mgCaffeineProvider, mgUnitProvider)
        
        // Create the template using the providers.
        return CLKComplicationTemplateUtilitarianSmallFlat(textProvider: combinedMGProvider,
                                                           imageProvider: flatUtilitarianImageProvider)
    }
    
    // Return a utilitarian large template.
    private func createUtilitarianLargeTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let flatUtilitarianImageProvider = CLKImageProvider(onePieceImage: #imageLiteral(resourceName: "CoffeeSmallFlat"))
        
        let mgCaffeineProvider = CLKSimpleTextProvider(text: String(data.mlWater(atDate: date)))
        let mgUnitProvider = CLKSimpleTextProvider(text: "mL Water", shortText: "mL")
        let combinedMGProvider = CLKTextProvider(format: "%@ %@", mgCaffeineProvider, mgUnitProvider)
        
        // Create the template using the providers.
        return CLKComplicationTemplateUtilitarianLargeFlat(textProvider: combinedMGProvider,
                                                           imageProvider: flatUtilitarianImageProvider)
    }
    
    // Return a circular small template.
    private func createCircularSmallTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let mgCaffeineProvider = CLKSimpleTextProvider(text: String(data.mlWater(atDate: date)))
        let mgUnitProvider = CLKSimpleTextProvider(text: "mL Water", shortText: "mL")
        
        // Create the template using the providers.
        return CLKComplicationTemplateCircularSmallStackText(line1TextProvider: mgCaffeineProvider,
                                                             line2TextProvider: mgUnitProvider)
    }
    
    // Return an extra large template.
    private func createExtraLargeTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let mgCaffeineProvider = CLKSimpleTextProvider(text: String(data.mlWater(atDate: date)))
        let mgUnitProvider = CLKSimpleTextProvider(text: "mL")
        
        // Create the template using the providers.
        return CLKComplicationTemplateExtraLargeStackText(line1TextProvider: mgCaffeineProvider,
                                                          line2TextProvider: mgUnitProvider)
    }
    
    // Return a graphic template that fills the corner of the watch face.
    private func createGraphicCornerTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let leadingValueProvider = CLKSimpleTextProvider(text: "0")
        leadingValueProvider.tintColor = data.color(forWaterDose: 0.0)
        
        let trailingValueProvider = CLKSimpleTextProvider(text: "500")
        trailingValueProvider.tintColor = data.color(forWaterDose: 500.0)
        
        let mgCaffeineProvider = CLKSimpleTextProvider(text: String(data.mlWater(atDate: date)))
        let mgUnitProvider = CLKSimpleTextProvider(text: "mL Water", shortText: "mL")
        mgUnitProvider.tintColor = data.color(forWaterDose: data.mlWater(atDate: date))
        let combinedMGProvider = CLKTextProvider(format: "%@ %@", mgCaffeineProvider, mgUnitProvider)
        
        let percentage = Float(min(data.mlWater(atDate: date) / 500.0, 1.0))
        let gaugeProvider = CLKSimpleGaugeProvider(style: .fill,
                                                   gaugeColors: [.green, .yellow, .red],
                                                   gaugeColorLocations: [0.0, 300.0 / 500.0, 450.0 / 500.0] as [NSNumber],
                                                   fillFraction: percentage)
        
        // Create the template using the providers.
        return CLKComplicationTemplateGraphicCornerGaugeText(gaugeProvider: gaugeProvider,
                                                             leadingTextProvider: leadingValueProvider,
                                                             trailingTextProvider: trailingValueProvider,
                                                             outerTextProvider: combinedMGProvider)
    }
    
    // Return a graphic circle template.
    private func createGraphicCircleTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let percentage = Float(min(data.mlWater(atDate: date) / 500.0, 1.0))
        let gaugeProvider = CLKSimpleGaugeProvider(style: .fill,
                                                   gaugeColors: [.green, .yellow, .red],
                                                   gaugeColorLocations: [0.0, 300.0 / 500.0, 450.0 / 500.0] as [NSNumber],
                                                   fillFraction: percentage)
        
        let mgCaffeineProvider = CLKSimpleTextProvider(text: String(data.mlWater(atDate: date)))
        let mgUnitProvider = CLKSimpleTextProvider(text: "mL Water", shortText: "mL")
        mgUnitProvider.tintColor = data.color(forWaterDose: data.mlWater(atDate: date))
        
        // Create the template using the providers.
        return CLKComplicationTemplateGraphicCircularOpenGaugeSimpleText(gaugeProvider: gaugeProvider,
                                                                         bottomTextProvider: CLKSimpleTextProvider(text: "mg"),
                                                                         centerTextProvider: mgCaffeineProvider)
    }
    
    // Return a large rectangular graphic template.
    private func createGraphicRectangularTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let imageProvider = CLKFullColorImageProvider(fullColorImage: #imageLiteral(resourceName: "CoffeeGraphicRectangular"))
        let titleTextProvider = CLKSimpleTextProvider(text: "Water Tracker", shortText: "Water")
        
        let mgCaffeineProvider = CLKSimpleTextProvider(text: String(data.mlWater(atDate: date)))
        let mgUnitProvider = CLKSimpleTextProvider(text: "mL Water", shortText: "mL")
        mgUnitProvider.tintColor = data.color(forWaterDose: data.mlWater(atDate: date))
        let combinedMGProvider = CLKTextProvider(format: "%@ %@", mgCaffeineProvider, mgUnitProvider)
        
        let percentage = Float(min(data.mlWater(atDate: date) / 500.0, 1.0))
        let gaugeProvider = CLKSimpleGaugeProvider(style: .fill,
                                                   gaugeColors: [.green, .yellow, .red],
                                                   gaugeColorLocations: [0.0, 300.0 / 500.0, 450.0 / 500.0] as [NSNumber],
                                                   fillFraction: percentage)
        
        // Create the template using the providers.
        
        return CLKComplicationTemplateGraphicRectangularTextGauge(headerImageProvider: imageProvider,
                                                                  headerTextProvider: titleTextProvider,
                                                                  body1TextProvider: combinedMGProvider,
                                                                  gaugeProvider: gaugeProvider)
    }
    
    // Return a circular template with text that wraps around the top of the watch's bezel.
    private func createGraphicBezelTemplate(forDate date: Date) -> CLKComplicationTemplate {
        
        // Create a graphic circular template with an image provider.
        let circle = CLKComplicationTemplateGraphicCircularImage(imageProvider: CLKFullColorImageProvider(fullColorImage: #imageLiteral(resourceName: "CoffeeGraphicCircular")))
        
        // Create the text provider.
        let mgCaffeineProvider = CLKSimpleTextProvider(text: String(data.mlWater(atDate: date)))
        let mgUnitProvider = CLKSimpleTextProvider(text: "mL Water", shortText: "mL")
        mgUnitProvider.tintColor = data.color(forWaterDose: data.mlWater(atDate: date))
        let combinedMGProvider = CLKTextProvider(format: "%@ %@", mgCaffeineProvider, mgUnitProvider)
               
        let numberOfCupsProvider = CLKSimpleTextProvider(text: String(data.totalCupsToday))
        let cupsUnitProvider = CLKSimpleTextProvider(text: "Cups", shortText: "C")
        cupsUnitProvider.tintColor = data.color(forTotalCups: data.totalCupsToday)
        let combinedCupsProvider = CLKTextProvider(format: "%@ %@", numberOfCupsProvider, cupsUnitProvider)
        
        let separator = NSLocalizedString(",", comment: "Separator for compound data strings.")
        let textProvider = CLKTextProvider(format: "%@%@ %@",
                                           combinedMGProvider,
                                           separator,
                                           combinedCupsProvider)
        
        // Create the bezel template using the circle template and the text provider.
        return CLKComplicationTemplateGraphicBezelCircularText(circularTemplate: circle,
                                                               textProvider: textProvider)
    }
    
    // Returns an extra large graphic template.
    private func createGraphicExtraLargeTemplate(forDate date: Date) -> CLKComplicationTemplate {
        
        // Create the data providers.
        let percentage = Float(min(data.mlWater(atDate: date) / 500.0, 1.0))
        let gaugeProvider = CLKSimpleGaugeProvider(style: .fill,
                                                   gaugeColors: [.green, .yellow, .red],
                                                   gaugeColorLocations: [0.0, 300.0 / 500.0, 450.0 / 500.0] as [NSNumber],
                                                   fillFraction: percentage)
        
        let mgCaffeineProvider = CLKSimpleTextProvider(text: String(data.mlWater(atDate: date)))
        
        return CLKComplicationTemplateGraphicExtraLargeCircularOpenGaugeSimpleText(
            gaugeProvider: gaugeProvider,
            bottomTextProvider: CLKSimpleTextProvider(text: "mL"),
            centerTextProvider: mgCaffeineProvider)
    }
}
