//
//  BeatCSSParser.swift
//  Originally based on CssParser gist by jgsamudio
//  https://gist.github.com/jgsamudio/adba6eb7afc96558bb35f18d5f74c16a
//
//  Created by Lauri-Matti Parppei on 2.8.2022.
//  Copyright © 2022 Lauri-Matti Parppei. All rights reserved.
//

import Foundation

public protocol BeatCssParserDelegate {
	func get(key:String)
}

public final class CssParser {
	
	var styles:[String:RenderStyle] = [:]
    var lineHeight = BeatStyles.lineHeight // default line height
    
	// Map property names to types
	let stringTypes:Set = ["textAlign", "text-align", "color", "font", "content"]
	let boolTypes:Set = ["bold", "italic", "underline", "uppercase", "indentSplitElements", "indent-split-elements", "sceneNumber", "scene-number"]
	let userSettings:Set = ["headingStyleBold", "headingStyleUnderline", "sceneHeadingSpacing"]

	var settings:BeatExportSettings?
	
	/// Parses the CSS file string into an array of CSS styles.
	/// - Parameter fileContent: CSS file content.
	/// - Returns: Array of CSS styles.
	func parse(fileContent: String, settings:BeatExportSettings? = nil) -> [String: RenderStyle] {
        self.settings = settings
		
		var styles:[String: Dictionary<String, String>] = [:]
		
		var pendingStyleName = ""
		var pendingStyleProperties = [String: String]()
		var pendingLine = ""
		
		var omit = false
		var previousOmit = ""
				
		for character in fileContent {
			if character == "/" && pendingStyleName == "" {
				if !omit {
					previousOmit = "/"
					continue
				}
				else if omit && previousOmit == "*" {
					omit = false
					previousOmit = ""
					continue
				}
			}
			else if character == "*" {
				if previousOmit == "/" {
					omit = true
					previousOmit = ""
					continue
				}
				else if omit {
					previousOmit = "*"
					continue
				}
			}
		
			// We're inside an omit block
			if omit { continue }
			 
			pendingLine.append(character)
			
			if character == "{" {
				pendingStyleName = pendingLine.replacingOccurrences(strings: ["\n", "{"])
				pendingLine = ""
			}
			else if character == ";" {
				let propertyLine = pendingLine.replacingOccurrences(strings: [";", "\n"])
				let key = propertyLine.removeTrailing(startWith: ":").replacingOccurrences(strings: [" "]).trimmingCharacters(in: .whitespaces)
				let value = propertyLine.removeLeading(startWith: ":").removeLeading(startWith: " ")
				
				pendingStyleProperties[key] = value
				pendingLine = ""
			}
			else if character == "}" {
				pendingStyleName = pendingStyleName.trimmingCharacters(in: .whitespaces)
                
                let styleNames = pendingStyleName.components(separatedBy: ",")
                
                for styleName in styleNames {
                    let key = styleName.trimmingCharacters(in: .whitespaces)
                    
                    if var existingStyles = styles[key] {
                        // Style already exists, let's overwrite rules when needed
                        for ruleKey in pendingStyleProperties.keys {
                            existingStyles[ruleKey] = pendingStyleProperties[ruleKey]
                        }
                        styles[key] = existingStyles // These are not pointers in Swift (?) so we need to add the style back to dictionary.
                    } else {
                        // Style doesn't exist, create new
                        styles[key] = pendingStyleProperties
                    }
                }
				
				pendingStyleProperties.removeAll()
				pendingStyleName = ""
				pendingLine = ""
			}
		}
		
		// Map the rules into actual styles
		// BTW, this is a silly approach -- why not check the type in RenderStyle property before using readValue()?
		for key in styles.keys {
			let dict:[String:String] = styles[key]!
			var rules = [String:Any]()
			
			for ruleKey in dict.keys {
				let value = dict[ruleKey]!
				
				// Different outcome based on the type
				if (stringTypes.contains(ruleKey)) {
					rules[ruleKey] = readValue(string: value, type: String.self)
				}
				else if (boolTypes.contains(ruleKey)) {
					rules[ruleKey] = readValue(string: value, type: Bool.self)
				} else {
                    let value = readValue(string: value, type: Double.self)
					rules[ruleKey] = value
                    
                    // Line height can be set DYNAMICALLY, and will affect other value calculations
                    if key == "page" && (ruleKey == "lineHeight" || ruleKey == "line-height") {
                        self.lineHeight = value as? CGFloat ?? BeatStyles.lineHeight
                    }
				}
			}
		
            let style = RenderStyle(rules: rules)
            style.name = key
            
			self.styles[key] = style
		}
		        
		return self.styles
	}
	
	func convertValueToString(_ value:Any) -> String {
		var userSettingValue = ""
		
		if value is Int { userSettingValue = String(value as? Int ?? 0) }
		else if value is Bool { userSettingValue = (value as! Bool) ? "true" : "false" }
		else if value is String { userSettingValue = String(value as? String ?? "") }
		
		return userSettingValue
	}
	
	func readValue<T: Decodable>(string:String, type: T.Type) -> Any {
		var value = string

		if value.contains("userSetting(") {
			for userSetting in userSettings {
				guard let val = BeatUserDefaults.shared().get(userSetting) else { continue }
				
				let userSettingValue = convertValueToString(val)
				value = value.replacingOccurrences(of: "userSetting(" + userSetting + ")", with: userSettingValue)
			}
		}
		if value.contains("userValue(") {
			for userSetting in userSettings {
				guard let val = BeatUserDefaults.shared().get(userSetting) else { continue }
				
				let userSettingValue = convertValueToString(val)
				value = value.replacingOccurrences(of: "userValue(" + userSetting + ")", with: userSettingValue)
			}
		}
		
		if value.contains("setting(") && settings != nil {
			for userSetting in userSettings {
				guard let val = settings?.value(forKey: userSetting) else { continue }
				
				let userSettingValue = convertValueToString(val)
				value = value.replacingOccurrences(of: "setting(" + userSetting + ")", with: userSettingValue)
			}
		}
		
		// Return plain string value
		if type == String.self {
			return value
		}
		
		// Return bool
		if type == Bool.self {
			if (value == "true" || value == "1") { return true }
			else { return false }
		}
				
		// Calculate different units based on *fixed values*
		value = value.replacingOccurrences(of: "ch", with: "* 7.25")
        value = value.replacingOccurrences(of: "l", with: "* \(self.lineHeight)")
		value = value.replacingOccurrences(of: "px", with: "")
		value = value.replacingOccurrences(of: " ", with: "")
		
		// ... and to be even more *safe* and *transparent*, let's use NSExpression 🍄
		let exp = NSExpression(format: value)
                
		return exp.expressionValue(with: nil, context: nil) ?? 0
	}
}
