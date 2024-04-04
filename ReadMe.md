# WIP: Custom Restrictions and Context

## About

An ArchivesSpace plugin that enhances the staff and public interfaces with
custom restrictions and additional contextual information.

## Installation

Install as you normally would and add `aspace_custom_restrictions_and_context` to
your list of enabled plugins in `AppConfig[:plugins]`.

Run the `setup-database` script before using since the plugin needs to update the
database.

## Configuration

The plugin accepts two configuration options. 

One disables the context and and location display on resources and archival objects. Set
```
AppConfig[:aspace_custom_restrictions_show_context] = false
```

The other disables the display of restrictions in the PUI. Set
```
AppConfig[:aspace_custom_restrictions_pui_enhance] = false
```

## Enhancements

### Staff Interface

The plugin adds a custom restriction sub-record to

1. accessions
1. resources
1. archival objects
1. digital objects
1. digital_object_components

which allows an editor to tag an object with more nuance than just the stock
`Restrictions Apply?` checkbox, though if that checkbox had been ticked, the plugin
will also use that data.

The plugin parses the custom restriction data and the `Restrictions Apply?` data and displays
a warning on the object that the restriction has been applied. It also displays the restriction text
on all of its descendants. The language displayed depends on the custom restriction selected or 
provides a default. See `frontend/locales/enums` for values supplied by the plugin. This is
displayed for both view mode for an object and in search & browse results.

Note that the custom restriction takes precendence over the `Restrictions Apply` checkbox for displays.

The plugin also displays the context (the hierarchical tree) for archival objects and the location
of the archival object or resource if a container instance is attached. The context and location
are both displayed on the view mode of an an object, while the location is only displayed in search results.

### PUI

The plugin adds a restriction note to the search & browse results and the object view similarly to the way it
enhances the staff interface.

## Enumerations

The plugin adds a new editable enumeration - `Custom Restriction Type`. If you add additional values to this
list, make sure that you also add translations in `frontend/locales/enums`.

## Note

In order to make this plugin useful for multiple versions of ArchivesSpace and to limit maintenance of
multiple version, the plugin uses javascript to enhance the layouts and makes one additional request per object.
For views of a single object this is one additional request, but for search results this will increase the
number of requests by the default page size.

## Credits

Plugin developed by Joshua Shaw [Joshua.D.Shaw@dartmouth.edu], Digital Library Technologies Group
Dartmouth Library, Dartmouth College
