//
//  BeatStyle.swift
//  BeatPagination2
//
//  Created by Lauri-Matti Parppei on 28.9.2023.
//

import Foundation
import BeatParsing
import OSLog

@objc public class BeatStylesheet:NSObject {
    public var styles:[String:RenderStyle] = [:]
    public var editorStyles:[String:RenderStyle] = [:]
    
    var settings:BeatExportSettings?
    
    var stylesheet:String?
    
    public init(url:URL, settings:BeatExportSettings? = nil) {
        self.settings = settings
                
        super.init()
        
        do {
            self.stylesheet = try String(contentsOf: url)
        } catch {
            print("Error loading editor stylesheet")
        }
        
        loadStyles()
    }
        
    /// Parses the style string
    public func loadStyles(additionalStyles:String = "") {
        // Parse render styles
        if self.stylesheet != nil {
            var stylesheet = String(stringLiteral: self.stylesheet!)
            stylesheet.append("\n\n" + additionalStyles)

            styles = CssParser().parse(fileContent: stylesheet, settings: self.settings)
        }
    }
    
    /// Reloads the given style
    @objc public func reload() {
        self.loadStyles()
    }
    
    @objc public func page() -> RenderStyle {
        guard let pageStyle = styles["page"] else {
            os_log("WARNING: No page style defined in stylesheet")
            return RenderStyle(rules: [:])
        }
        return pageStyle
    }
    
    @objc public func forElement(_ name:String) -> RenderStyle {
        return styles[name] ?? RenderStyle(rules: ["width-a4": self.page().defaultWidthA4, "width-us": self.page().defaultWidthLetter])
    }
}


// MARK: Shorthands for the styles
@objc extension BeatStylesheet {
    @objc public var action:RenderStyle {
        return self.forElement(Line.typeName(.action))
    }
    @objc public var dialogue:RenderStyle {
        return self.forElement(Line.typeName(.dialogue))
    }
    @objc public var parenthetical:RenderStyle {
        return self.forElement(Line.typeName(.parenthetical))
    }
    @objc public var character:RenderStyle {
        return self.forElement(Line.typeName(.character))
    }
    @objc public var titlePageElement:RenderStyle {
        return self.forElement(Line.typeName(.titlePageTitle))
    }
    @objc public var dualDialogueCharacter:RenderStyle {
        return self.forElement(Line.typeName(.dualDialogueCharacter))
    }
    @objc public var dualDialogueParenthetical:RenderStyle {
        return self.forElement(Line.typeName(.dualDialogueParenthetical))
    }
    @objc public var dualDialogue:RenderStyle {
        return self.forElement(Line.typeName(.dualDialogue))
    }
    @objc public var transition:RenderStyle {
        return self.forElement(Line.typeName(.transitionLine))
    }    
}
