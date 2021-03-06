import UIKit

public class SingleNameEntryController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    public var selectedContact: Contact?
    var allConctacts = [Contact]()
    var suggestedContacts = [Contact]()
    public var songSelectionCompletionHandler: ((Song, Contact?) -> Void)!
    
    public var contactService = ContactService()
    
    @IBOutlet public weak var nameEntryTextField: UITextField!
    @IBOutlet public weak var lastNameLabel: UILabel!
    @IBOutlet public weak var nameSuggestionTableView: UITableView!
    @IBOutlet public weak var findSongsButton: UIBarButtonItem!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        initializeNameEntry()
        
        contactService.retrieveAllContacts() {
            contactListResult in
            
            switch(contactListResult) {
            case .Success(let contacts):
                self.allConctacts = contacts
            case .Failure(let error):
                print("Unable to retrieve contacts: \(error)")
            }
        }
    }
    
    func initializeNameEntry() {
        nameEntryTextField.returnKeyType = .Go
        nameEntryTextField.delegate = self
        nameEntryTextChanged(nameEntryTextField)
        nameSuggestionTableView.hidden = true
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override public func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        nameEntryTextField.becomeFirstResponder()
    }
    

    // MARK: - Navigation

    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let spotifySongSelectionTableController = segue.destinationViewController as? SpotifySongSelectionTableController {
            spotifySongSelectionTableController.searchContact = selectedContact
            spotifySongSelectionTableController.songSelectionCompletionHandler = songSelectionCompletionHandler
        }
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return suggestedContacts.count
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("NameSuggestionTableCell", forIndexPath: indexPath)
        
        let contact = suggestedContacts[indexPath.row]
        cell.textLabel?.text = contact.fullName

        return cell
    }
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedContact = suggestedContacts[indexPath.row]
        nameSuggestionTableView.hidden = true
        setNameEntryTextAndLastNameLabelForSelectedContact()
    }
    
    func setNameEntryTextAndLastNameLabelForSelectedContact() {
        let firstName = selectedContact!.firstName ?? ""
        let lastName = selectedContact!.lastName ?? ""
        nameEntryTextField.text = firstName
        if firstName.isEmpty {
            nameEntryTextField.text = lastName
            lastNameLabel.text = ""
        } else {
            lastNameLabel.text = lastName.isEmpty ? "" : "(\(lastName))"
        }
    }
    
    @IBAction public func nameEntryTextChanged(sender: UITextField) {
        let trimmedText = nameEntryTextField.text!.trim()
        findSongsButton.enabled = !trimmedText.isEmpty
        
        selectedContact = nil
        lastNameLabel.text = ""
        
        reloadNameSuggestionTableViewForText(trimmedText)
    }
    
    func reloadNameSuggestionTableViewForText(text: String) {
        suggestedContacts.removeAll(keepCapacity: false)
        if !text.isEmpty {
            for contact in allConctacts {
                let contactWords = contact.fullName.componentsSeparatedByString(" ")
                    .map({ $0.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) })
                let matchingWords = contactWords.filter({ $0.lowercaseString.hasPrefix(text.lowercaseString) })
                if !matchingWords.isEmpty {
                    suggestedContacts.append(contact)
                }
            }
        }
        
        suggestedContacts.sortInPlace({ $0.fullName < $1.fullName })
        nameSuggestionTableView.hidden = suggestedContacts.isEmpty
        nameSuggestionTableView.reloadData()
    }
    
    @IBAction public func cancelPressed(sender: UIBarButtonItem) {
        navigationController?.popViewControllerAnimated(true)
    }
    
    public func textFieldShouldReturn(textField: UITextField) -> Bool {
        print("textFieldShouldReturn")
        if findSongsButton.enabled {
            findSongsPressed(textField)
        }
        return findSongsButton.enabled
    }
    
    @IBAction public func findSongsPressed(sender: AnyObject) {
        if selectedContact == nil {
            selectedContact = Contact(id: -1,
                firstName: nameEntryTextField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()),
                lastName: nil)
        }
        performSegueWithIdentifier("SelectSongDifferentContactSegue", sender: sender)
    }
}
