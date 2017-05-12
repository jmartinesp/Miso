//
//  FormElementTest.swift
//  Miso
//
//  Created by Jorge Martín Espinosa on 22/4/17.
//  Copyright © 2017 Jorge Martín Espinosa. All rights reserved.
//

import XCTest
@testable import Miso

class FormElementTest: XCTestCase {
    
    func testHasAssociatedControls() {
        let html = "<form id=1><button id=1><fieldset id=2 /><input id=3><keygen id=4><object id=5>"
            + "<output id=6><select id=7><option></select><textarea id=8><p id=9>"
        let doc = Miso.parse(html: html)
        
        let form = doc.select("form").first as? FormElement
        XCTAssertEqual(8, form?.elements.count)
    }
    
    func testCreatesFormData() {
        let html = "<form><input name='one' value='two'><select name='three'><option value='not'>" +
            "<option value='four' selected><option value='five' selected><textarea name=six>seven</textarea>" +
            "<input name='seven' type='radio' value='on' checked><input name='seven' type='radio' value='off'>" +
            "<input name='eight' type='checkbox' checked><input name='nine' type='checkbox' value='unset'>" +
            "<input name='ten' value='text' disabled>" +
            "</form>"
        
        let doc = Miso.parse(html: html)
        let form = doc.select("form").first as? FormElement
        let data = form?.formData
        
        XCTAssertEqual(6, data?.count)
        XCTAssertEqual("one=two", data?[0].description)
        XCTAssertEqual("three=four", data?[1].description)
        XCTAssertEqual("three=five", data?[2].description)
        XCTAssertEqual("six=seven", data?[3].description)
        XCTAssertEqual("seven=on", data?[4].description) // set
        XCTAssertEqual("eight=on", data?[5].description) // default
        // nine should not appear, not checked checkbox
        // ten should not appear, disabled
    }
    
    /*
 @Test public void createsSubmitableConnection() {
 String html = "<form action='/search'><input name='q'></form>";
 Document doc = Jsoup.parse(html, "http://example.com/");
 doc.select("[name=q]").attr("value", "jsoup");
 
 FormElement form = ((FormElement) doc.select("form").first());
 Connection con = form.submit();
 
 assertEquals(Connection.Method.GET, con.request().method());
 assertEquals("http://example.com/search", con.request().url().toExternalForm());
 List<Connection.KeyVal> dataList = (List<Connection.KeyVal>) con.request().data();
 assertEquals("q=jsoup", dataList.get(0).toString());
 
 doc.select("form").attr("method", "post");
 Connection con2 = form.submit();
 assertEquals(Connection.Method.POST, con2.request().method());
 }
 
 @Test public void actionWithNoValue() {
 String html = "<form><input name='q'></form>";
 Document doc = Jsoup.parse(html, "http://example.com/");
 FormElement form = ((FormElement) doc.select("form").first());
 Connection con = form.submit();
 
 assertEquals("http://example.com/", con.request().url().toExternalForm());
 }
 
 @Test public void actionWithNoBaseUri() {
 String html = "<form><input name='q'></form>";
 Document doc = Jsoup.parse(html);
 FormElement form = ((FormElement) doc.select("form").first());
 
 
 boolean threw = false;
 try {
 Connection con = form.submit();
 } catch (IllegalArgumentException e) {
 threw = true;
 assertEquals("Could not determine a form action URL for submit. Ensure you set a base URI when parsing.",
 e.getMessage());
 }
 assertTrue(threw);
 }*/
    
    func testFormsAddedAfterParseAreFormElements() {
        let doc = Miso.parse(html: "<body />")
        doc.body?.html(replaceWith: "<form action='http://example.com/search'><input name='q' value='search'>")
        let formElement = doc.select("form").first
        XCTAssert(formElement is FormElement)
        
        let form = formElement as? FormElement
        XCTAssertEqual(1, form?.elements.count)
    }
    
    func testControlsAddedAfterParseAreLinkedWithForms() {
        let doc = Miso.parse(html: "<body />")
        doc.body?.html(replaceWith: "<form />")
        
        let formElement = doc.select("form").first
        formElement?.append(html: "<input name=foo value=bar>")
        
        XCTAssert(formElement is FormElement)
        let form = formElement as? FormElement
        XCTAssertEqual(1, form?.elements.count)
        
        let data = form?.formData
        XCTAssertEqual("foo=bar", data?[0].description)
    }
    
    func testUsesOnForCheckboxValueIfNoValueSet() {
        let doc = Miso.parse(html: "<form><input type=checkbox checked name=foo></form>")
        let form = doc.select("form").first as? FormElement
        let data = form?.formData
        
        XCTAssertEqual("on", data?[0].value)
        XCTAssertEqual("foo", data?[0].key)
    }
    
    func testAdoptedFormsRetainInputs() {
        let html = "<html>\n" +
            "<body>  \n" +
            "  <table>\n" +
            "      <form action=\"/hello.php\" method=\"post\">\n" +
            "      <tr><td>User:</td><td> <input type=\"text\" name=\"user\" /></td></tr>\n" +
            "      <tr><td>Password:</td><td> <input type=\"password\" name=\"pass\" /></td></tr>\n" +
            "      <tr><td><input type=\"submit\" name=\"login\" value=\"login\" /></td></tr>\n" +
            "   </form>\n" +
            "  </table>\n" +
            "</body>\n" +
            "</html>"
        
        let doc = Miso.parse(html: html)
        let form = doc.select("form").first as? FormElement
        let data = form?.formData
        
        XCTAssertEqual(3, data?.count)
        XCTAssertEqual("user", data?[0].key)
        XCTAssertEqual("pass", data?[1].key)
        XCTAssertEqual("login", data?[2].key)
    }
    
}
