//
// Created by Jorge Martín Espinosa on 17/4/17.
// Copyright (c) 2017 Jorge Martín Espinosa. All rights reserved.
//

import Foundation

/**
 * A HTML Form Element provides ready access to the form fields/controls that are associated with it. It also allows a
 * form to easily be submitted.
 */
public class FormElement: Element {

    public private(set) var elements = [Element]()

    public override init(tag: Tag, baseUri: String?, attributes: Attributes) {
        super.init(tag: tag, baseUri: baseUri, attributes: attributes)
    }

    /**
     * Add a form control element to this form.
     * @param element form control to add
     * @return this form element, for chaining
     */
    public func append(_ element: Element) {
        elements.append(element)
    }
    
    public struct KeyVal: CustomStringConvertible {
    
        public let key: String
        public let value: String
    
        public var description: String {
            return "\(key)=\(value)"
        }
    }
    
    public var formData: [KeyVal] {
        var data = [KeyVal]()
        
        // iterate the form control elements and accumulate their values
        for element in elements {
            if !element.tag.isFormSubmittable { continue } // contents are form listable, superset of submitable
            if element.has(attr: "disabled") { continue }
            
            let name = element.attr("name")
            if name == nil { continue }
            
            let type = element.attr("type")?.lowercased()
            
            if "select" == element.tagName {
                let options = element.select("option[selected]")
                var set = false
                
                for option in options {
                    data.append(KeyVal(key: name!, value: option.val ?? ""))
                    set = true
                }
                
                if !set {
                    if let option = element.select("option").first {
                        data.append(KeyVal(key: name!, value: option.val ?? ""))
                    }
                }
            } else if "checkbox" == type || "radio" == type {
                // only add checkbox or radio if they have the checked attribute
                if element.has(attr: "checked") {
                    let val = element.val ?? "on"
                    data.append(KeyVal(key: name!, value: val))
                }
            } else {
                data.append(KeyVal(key: name!, value: element.val ?? ""))
            }
        }
        
        return data
    }
}
