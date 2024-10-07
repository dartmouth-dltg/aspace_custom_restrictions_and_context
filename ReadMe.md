# Aspace Custom Restrictions and Context

## About

An ArchivesSpace plugin that enhances the staff and public interfaces with
custom restrictions and additional contextual information.

## Installation

Install as you normally would and add `aspace_custom_restrictions_and_context` to
your list of enabled plugins in `AppConfig[:plugins]`.

Run the `setup-database` script before using since the plugin needs to update the
database.

The plugin does not have any additional dependencies so you do not need to run
the `initialize-plugin` script.

### Reindex Required

A soft reindex is required. See the ArchivesSpace 
[Tech Docs](https://archivesspace.github.io/tech-docs/administration/indexes.html).

## Configuration

The plugin accepts several configuration options. 

Disable the context and and location display on resources and archival objects. Set
```
AppConfig[:aspace_custom_restrictions_show_context] = false
```

Disable the restrictions on Staff search results. Set
```
AppConfig[:aspace_custom_restrictions_sui_search_enhance] = false
```

Disable the display of restrictions in the PUI. Set
```
AppConfig[:aspace_custom_restrictions_pui_enhance] = false
```

To limit the  of display certain restrictions to specific object types, use a configuration
options like
```
AppConfig[:aspace_custom_restriction_type_mapping] = {
  'some_materials_restricted' => [
    'otherlevel',
    'box', # this is a potential otherlevel type
    'collection',
    'series',
    'subseries'
  ]
}
```
Note that the key(s) must correspond to the restriction types set in the Custom Restriction Type
enumeration. The array list should consist of the levels or (in the case of accessions, 
digital objects, and digital object components) the jsonmodel_type (e.g. `digital_object`). 
If you use `otherlevel`, include the `otherlevel` types you use. The default is to apply all
restriction types to all relevant objects (see below).

If you have Conditions Governing Access notes and have noted that a object is open, you can
direct the restrictions plugin to skip/ignore certain phrases. For example, if you had added
notes that state `open for access`, you can add that to the 
`aspace_custom_restrictions_access_note_skip_phrases` configuration option.
```
AppConfig[:aspace_custom_restrictions_access_note_skip_phrases] = [
  'open for access'
]
```
You can have multiple skip phrases in the configuration option.

You can also completely turn off the use of Conditions Governing Access notes in the restriction
calculation.
```
AppConfig[:aspace_custom_restrictions_use_accessrestrict] = false
```

Tree decoration is also optional. You can choose to turn these off to conserve server resources.
```
AppConfig[:aspace_custom_restrictions_staff_tree] = false
```
and
```
AppConfig[:aspace_custom_restrictions_pui_tree] = false
```
Staff faceting is alos optional and defaults to off. To turn it on, set
```
AppConfig[:aspace_custom_restrictions_faceting] = true
```

## Enhancements

### Staff Interface

The plugin adds a custom restriction sub-record to

1. accessions
1. resources
1. archival objects
1. digital objects
1. digital object components

which allows an editor to tag an object with more nuance than just the stock
`Restrictions Apply?` checkbox. However, if that checkbox had been ticked, the plugin
will also use that data.

The plugin parses the custom restriction data, any Conditions Governing Access notes,
and the `Restrictions Apply?` data and displays a warning on the object that the restriction
has been applied. It also displays the restriction text on all of its descendants. The
language displayed depends on the custom restriction selected or 
provides a default. See `frontend/locales/enums` for values supplied by the plugin. This is
displayed for both view mode for an object and in search & browse results.

Note that the precedence order for restrictions is

1. Custom restriction
1. Conditions Governing Access note
1. `Restrictions Apply?` checkbox

The plugin also displays the context (the hierarchical tree) for archival objects and/or the location
of the archival object, resource, or accession if a container instance is attached. The context and location
are both displayed on the view mode of an archival object, while the location is only displayed in search results.
Digital object components will also be enhanced with an additional context tree in view mode.

Finally, unless configured otherwise, the trees for resources and digital objects are decorated with warnings for objects in the tree
that have a restriction.

### PUI

The plugin adds a restriction note to the search & browse results and the object view similarly to the way it
enhances the staff interface. Unless configured otherwise, trees for resources and digital objects are also 
decorated with warnings for objects in the tree that have a restriction.

## Enumerations

The plugin adds a new editable enumeration - `Custom Restriction Type`. If you add additional values to this
list, make sure that you also add translations in `frontend/locales/enums`.

## Note

### Performance

In order to make this plugin useful for multiple versions of ArchivesSpace and to limit maintenance of
multiple versions, the plugin uses javascript to enhance the tree layouts and makes one additional request 
per tree object. Depending on the resources available to your ArchivesSpace instance, you may notice some
performance impacts.

### Asset Aggregation

The css and javascript files are aggregated on startup for both the pui and staff interfaces to prevent
cache issues.

## Credits

Plugin developed by Joshua Shaw [Joshua.D.Shaw@dartmouth.edu], Digital Library Technologies Group
Dartmouth Library, Dartmouth College
