/* Time-stamp: <2007-06-01 23:03:58 jcs>
|
|  Copyright (C) 2002-2006 Jorg Schuler <jcsjcs at users sourceforge net>
|  Part of the gtkpod project.
| 
|  URL: http://www.gtkpod.org/
|  URL: http://gtkpod.sourceforge.net/
|
|  The code contained in this file is free software; you can redistribute
|  it and/or modify it under the terms of the GNU Lesser General Public
|  License as published by the Free Software Foundation; either version
|  2.1 of the License, or (at your option) any later version.
|
|  This file is distributed in the hope that it will be useful,
|  but WITHOUT ANY WARRANTY; without even the implied warranty of
|  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
|  Lesser General Public License for more details.
|
|  You should have received a copy of the GNU Lesser General Public
|  License along with this code; if not, write to the Free Software
|  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
|
|  iTunes and iPod are trademarks of Apple
|
|  This product is not supported/written/published by Apple!
|
|  $Id: itdb_photoalbum.c 1515 2007-06-01 14:19:21Z jcsjcs $
*/
#include <config.h>

#include "itdb_private.h"
#include "itdb_device.h"
#include "db-artwork-parser.h"
#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <glib/gi18n-lib.h>
#ifdef HAVE_GDKPIXBUF
#include <gdk-pixbuf/gdk-pixbuf.h>
#endif

/* Short summary:

   itdb_photodb_parse():
       Read an existing PhotoDB.

   itdb_photodb_create():
       Create a new Itdb_PhotoDB structure. The Photo Library Album is
       (first album) is created automatically.

   itdb_photodb_add_photo(), itdb_photodb_add_photo_from_data():
       Add a photo to the PhotoDB (from file or from a chunk of
       memory). It is automatically added to the Photo Library Album
       (first album), which is created if it does not exist already.

   itdb_photodb_photoalbum_create():
       Create and add a new photoalbum.

   itdb_photodb_photoalbum_add_photo():
       Add a photo (Itdb_Artwork) to an existing photoalbum.

   itdb_photodb_photoalbum_remove():
       Remove an existing photoalbum. Pictures can be kept in the
       Photo Library or automatically removed as well.

   itdb_photodb_remove_photo():
       Remove a photo either from a photoalbum or completely from the database.

   itdb_photodb_write():
       Write out your PhotoDB.

   itdb_photodb_free():
       Free all memory taken by the PhotoDB.

   itdb_photodb_photoalbum_by_name():
       Find the first photoalbum with a given name or the Photo
       Library Album if called with no name.


   If you cannot add photos because your iPod is not recognized, you
   may have to set the iPod model by calling

   itdb_device_set_sysinfo (db->device, "ModelNumStr", model);

   For example, "MA450" would stand for an 80 GB 6th generation iPod
   Video. See itdb_device.c for a list of supported models.
   
   This information will be written to the iPod when the PhotoDB is
   saved (itdb_device_write_sysinfo() is called).
*/


static Itdb_PhotoDB *itdb_photodb_new (void);
static void itdb_photodb_photoalbum_free (Itdb_PhotoAlbum *pa);

/* Set @error with standard error message */
static void error_no_photos_dir (const gchar *mp, GError **error)
{
    gchar *str;

    g_return_if_fail (mp);

    if (error)
    {
	str = g_build_filename (mp, "iPod_Control", "Photos", NULL);
	g_set_error (error,
		     ITDB_FILE_ERROR,
		     ITDB_FILE_ERROR_NOTFOUND,
		     _("Photos directory not found: '%s' (or similar)."),
		     str);
	g_free (str);
    }
}


/**
 * itdb_get_photos_dir:
 * @mountpoint: mountpoint of iPod
 *
 * Retrieve the Photo directory by
 * first calling itdb_get_control_dir() and then adding 'Photos'
 *
 * Return value: path to the Artwork directory or NULL of
 * non-existent. Must g_free() after use.
 */
gchar *itdb_get_photos_dir (const gchar *mountpoint)
{
    gchar *p_ipod[] = {"Photos", NULL};
    /* Use an array with all possibilities, so further extension will
       be easy */
    gchar **paths[] = {p_ipod, NULL};
    gchar ***ptr;
    gchar *result = NULL;

    g_return_val_if_fail (mountpoint, NULL);

    for (ptr=paths; *ptr && !result; ++ptr)
    {
	result = itdb_resolve_path (mountpoint, (const gchar **)*ptr);
    }
    return result;
}

/**
 * itdb_get_photodb_path:
 * @mountpoint: the iPod mountpoint
 *
 * Retrieve a path to the Photo DB
 *
 * Return value: path to the PhotoDB or NULL if non-existent. Must
 * g_free() after use.
 **/
gchar *itdb_get_photodb_path (const gchar *mountpoint)
{
    gchar *photo_dir, *path=NULL;

    g_return_val_if_fail (mountpoint, NULL);

    photo_dir = itdb_get_photos_dir (mountpoint);

    if (photo_dir)
    {
	path = itdb_get_path (photo_dir, "Photo Database");
	g_free (photo_dir);
    }

    return path;
}

/**
 * itdb_get_photos_thumb_dir:
 * @mountpoint: the iPod mountpoint
 *
 * Retrieve the Photo Thumbnail directory by
 * first calling itdb_get_control_dir() and then adding 'Photos/Thumbs'
 *
 * Return value: path to the Artwork directory or NULL of
 * non-existent. Must g_free() after use.
 */
gchar *itdb_get_photos_thumb_dir (const gchar *mountpoint)
{
    gchar *control_dir;
    gchar *result = NULL;
    gchar *dir = "Thumbs";

    g_return_val_if_fail (mountpoint, NULL);
    g_return_val_if_fail (dir, NULL);

    control_dir = itdb_get_photos_dir (mountpoint);
    if (control_dir)
    {
	const gchar *p_dir[] = {NULL, NULL};
	p_dir[0] = dir;
	result = itdb_resolve_path (control_dir, p_dir);
	g_free (control_dir);
    }
    return result;
}


/**
 * itdb_photodb_parse:
 * @mp: mountpoint of the iPod
 * @error: will contain the error description when an error occured.
 *
 * Parses the photo database of an iPod mounted at @mp.
 *
 * Return value: the imported PhotoDB or NULL in case of an error.
 **/
Itdb_PhotoDB *itdb_photodb_parse (const gchar *mp, GError **error)
{
    gchar *photos_dir;
    Itdb_PhotoDB *photodb = NULL;

    photos_dir = itdb_get_photos_dir (mp);

    if (!photos_dir)
    {
	error_no_photos_dir (mp, error);
	return NULL;
    }
    g_free (photos_dir);

    photodb = itdb_photodb_new ();
    itdb_device_set_mountpoint (photodb->device, mp);
    ipod_parse_photo_db (photodb);

    /* if photodb is empty, create a valid photodb including the main
       Photo Library album */
    if (!photodb->photos && !photodb->photoalbums)
    {
	itdb_photodb_free (photodb);
	photodb = itdb_photodb_create (mp);
    }

    return photodb;
}


/**
 * itdb_photodb_create:
 * @mountpoint: mountpoint or NULL.
 *
 * Creates a new Itdb_PhotoDB. If mountpoint is NULL, you will have to
 * set it manually later by calling itdb_device_set_mountpoint().
 *
 * Return value: a newly created Itdb_PhotoDB to be freed with
 * itdb_photodb_free() when it's no longer needed. The Photo Library
 * Album is created automatically.
 **/
Itdb_PhotoDB *itdb_photodb_create (const gchar *mountpoint)
{
    Itdb_PhotoDB *photodb = itdb_photodb_new ();
    Itdb_PhotoAlbum *album;

    album = itdb_photodb_photoalbum_create (photodb, _("Photo Library"), -1);
    album->album_type = 1; /* Photo Library */

    if (mountpoint)
    {
	itdb_device_set_mountpoint (photodb->device, mountpoint);
    }

    return photodb;
}



static Itdb_PhotoDB *itdb_photodb_new (void)
{
    Itdb_PhotoDB *photodb;

    photodb = g_new0 (Itdb_PhotoDB, 1);
    photodb->device = itdb_device_new ();

    return photodb;
}



/** 
 * itdb_photodb_free:
 * @photodb: an #Itdb_PhotoDB
 *
 * Free the memory taken by @photodb. 
 **/
void itdb_photodb_free (Itdb_PhotoDB *photodb)
{
	if (photodb)
	{
		g_list_foreach (photodb->photoalbums,
				(GFunc)(itdb_photodb_photoalbum_free), NULL);
		g_list_free (photodb->photoalbums);
		g_list_foreach (photodb->photos,
				(GFunc)(itdb_artwork_free), NULL);
		g_list_free (photodb->photos);
		itdb_device_free (photodb->device);

		if (photodb->userdata && photodb->userdata_destroy)
		    (*photodb->userdata_destroy) (photodb->userdata);

		g_free (photodb);
	}
}




G_GNUC_INTERNAL gint itdb_get_free_photo_id ( Itdb_PhotoDB *db ) 
{
	gint photo_id = 0;
	GList *it;

	for (it = db->photos; it != NULL; it = it->next) {
		Itdb_Artwork *artwork;

		artwork = (Itdb_Artwork *)it->data;
		if( artwork->id > photo_id )
			photo_id = artwork->id;
	}
	return photo_id + 1;
}

static void itdb_photodb_photoalbum_free (Itdb_PhotoAlbum *album)
{
    if (album)
    {
	g_free (album->name);
	g_list_free (album->members);

	if (album->userdata && album->userdata_destroy)
	    (*album->userdata_destroy) (album->userdata);

	g_free (album);
    }
}


/* called by itdb_photodb_add_photo() and
   itdb_photodb_add_photo_from_data() */
static Itdb_Artwork *itdb_photodb_add_photo_internal (Itdb_PhotoDB *db,
						      const gchar *filename,
						      const guchar *image_data,
						      gsize image_data_len,
						      gpointer pixbuf,
						      gint position,
						      gint rotation,
						      GError **error)
{
#ifdef HAVE_GDKPIXBUF
    gboolean result;
    Itdb_Artwork *artwork;
    Itdb_PhotoAlbum *album;
    const Itdb_ArtworkFormat *format;

    g_return_val_if_fail (db, NULL);
    g_return_val_if_fail (db->device, NULL);
    g_return_val_if_fail (filename || image_data, NULL);
    g_return_val_if_fail (!(image_data && (image_data_len == 0)), NULL);
    g_return_val_if_fail (!(pixbuf && (!GDK_IS_PIXBUF (pixbuf))), NULL);

    if (!ipod_supports_photos (db->device))
    {
	const Itdb_IpodInfo *ipodinfo = itdb_device_get_ipod_info (db->device);
	const gchar *model, *generation;

	if (!ipodinfo)
	{
	    g_set_error (error, 0, -1,
			 _("You need to specify the iPod model used before photos can be added."));
	    return NULL;
	    /* For information: The model is set by calling the rather
	       unintuitive function itdb_device_set_sysinfo as
	       follows:

	       itdb_device_set_sysinfo (db->device, "ModelNumStr", model);

	       For example, "MA450" would stand for an 80 GB 6th
	       generation iPod Video. See itdb_device.c for a list of
	       supported models.

	       This information will be written to the iPod when the
	       PhotoDB is saved (itdb_device_write_sysinfo() is called).
	    */
	}

	model = itdb_info_get_ipod_model_name_string (ipodinfo->ipod_model);
	generation = itdb_info_get_ipod_generation_string (ipodinfo->ipod_generation);
	g_return_val_if_fail (model && generation, NULL);
	g_set_error (error, 0, -1,
		     _("Your iPod does not seem to support photos. Maybe you need to specify the correct iPod model number? It is currently set to 'x%s' (%s/%s)."),
		     ipodinfo->model_number, generation, model);
	return NULL;
    }

    /* check if filename is valid */
    if (filename)
    {
	struct stat statbuf;
	if (g_stat  (filename, &statbuf) != 0)
	{
	    g_set_error (error, 0, -1,
			 _("Could not access file '%s'. Photo not added."),
			 filename);
	    return NULL;
	}
    }

    artwork = itdb_artwork_new ();

    /* Add a thumbnail for every supported format */
    format = itdb_device_get_artwork_formats (db->device);
    g_return_val_if_fail (format, NULL);

    for(result = TRUE; format->type != -1 && result == TRUE; format++)
    {
	if((format->type == ITDB_THUMB_COVER_SMALL) ||
	   (format->type == ITDB_THUMB_COVER_LARGE))
	    continue;
	if (filename)
	{
	    result = itdb_artwork_add_thumbnail (artwork,
						 format->type,
						 filename,
						 rotation,
						 error);
	}
	if (image_data)
	{
	    result = itdb_artwork_add_thumbnail_from_data (artwork,
							   format->type,
							   image_data,
							   image_data_len,
							   rotation,
							   error);
	}
	if (pixbuf) 
	{
	  result = itdb_artwork_add_thumbnail_from_pixbuf (artwork,
							   format->type, 
							   pixbuf,
							   rotation,
							   error);
	}
    }

    if (result != TRUE)
    {
	itdb_artwork_free (artwork);
	g_set_error (error, 0, -1,
		     _("Unexpected error in itdb_photodb_add_photo_internal() while adding photo, please report."));
	return NULL;
    }

    /* Add artwork to the list of photos */
    /* (it would be sufficient to append to the end) */
    db->photos = g_list_insert (db->photos, artwork, position);

    /* Add artwork to the first album */
    album = itdb_photodb_photoalbum_by_name (db, NULL);
    if (!album)
    {
	album = itdb_photodb_photoalbum_create (db, _("Photo Library"), -1);
	album->album_type = 1; /* Photo Library */
    }
    itdb_photodb_photoalbum_add_photo (db, album, artwork, position);

    return artwork;
#else
    g_set_error (error, 0, -1,
		 _("Library compiled without gdk-pixbuf support. Picture support is disabled."));
    return NULL;
#endif
}



/**
 * itdb_photodb_add_photo:
 * @db: the #Itdb_PhotoDB to add the photo to.
 * @filename: file with the photo to add.
 * @position: position where to insert the new photo (-1 to append at
 * the end)
 * @rotation: angle by which the image should be rotated
 * counterclockwise. Valid values are 0, 90, 180 and 270.
 * @error: return location for a #GError or NULL
 * 
 * Add a photo to the PhotoDB. The photo is automatically added to the
 * first Photoalbum, which by default contains a list of all photos in
 * the database. If no Photoalbums exist one is created automatically.
 *
 * For the rotation angle you can also use the gdk constants
 * GDK_PIXBUF_ROTATE_NONE, ..._COUNTERCLOCKWISE, ..._UPSIDEDOWN AND
 * ..._CLOCKWISE.
 *
 * Return value: a pointer to the added photo.
 **/
Itdb_Artwork *itdb_photodb_add_photo (Itdb_PhotoDB *db,
				      const gchar *filename,
				      gint position,
				      gint rotation,
				      GError **error)
{
    g_return_val_if_fail (db, FALSE);
    g_return_val_if_fail (filename, FALSE);

    return itdb_photodb_add_photo_internal (db, filename, NULL, 0, NULL,
					    position, rotation, error);
}


/**
 * itdb_photodb_add_photo_from_data:
 * @db: the #Itdb_PhotoDB to add the photo to.
 * @image_data: chunk of memory containing the image data (for example
 * a jpg file)
 * @image_data_len: length of above chunk of memory
 * @position: position where to insert the new photo (-1 to append at
 * the end)
 * @rotation: angle by which the image should be rotated
 * counterclockwise. Valid values are 0, 90, 180 and 270.
 * @error: return location for a #GError or NULL
 * 
 * Add a photo to the PhotoDB. The photo is automatically added to the
 * first Photoalbum, which by default contains a list of all photos in
 * the database. If no Photoalbums exist one is created automatically.
 *
 * For the rotation angle you can also use the gdk constants
 * GDK_PIXBUF_ROTATE_NONE, ..._COUNTERCLOCKWISE, ..._UPSIDEDOWN AND
 * ..._CLOCKWISE.
 *
 * Return value: a pointer to the added photo.
 **/
Itdb_Artwork *itdb_photodb_add_photo_from_data (Itdb_PhotoDB *db,
						const guchar *image_data,
						gsize image_data_len,
						gint position,
						gint rotation,
						GError **error)
{
    g_return_val_if_fail (db, FALSE);
    g_return_val_if_fail (image_data, FALSE);

    return itdb_photodb_add_photo_internal (db, NULL, 
					    image_data, image_data_len,
					    NULL, position, rotation, error);
}

/**
 * itdb_photodb_add_photo_from_pixbuf:
 * @db: the #Itdb_PhotoDB to add the photo to.
 * @pixbuf: a #GdkPixbuf to use as the image data
 * @position: position where to insert the new photo (-1 to append at
 * the end)
 * @rotation: angle by which the image should be rotated
 * counterclockwise. Valid values are 0, 90, 180 and 270.
 * @error: return location for a #GError or NULL
 * 
 * Add a photo to the PhotoDB. The photo is automatically added to the
 * first Photoalbum, which by default contains a list of all photos in
 * the database. If no Photoalbums exist one is created automatically.
 *
 * For the rotation angle you can also use the gdk constants
 * GDK_PIXBUF_ROTATE_NONE, ..._COUNTERCLOCKWISE, ..._UPSIDEDOWN AND
 * ..._CLOCKWISE.
 *
 * Return value: a pointer to the added photo.
 **/
Itdb_Artwork *itdb_photodb_add_photo_from_pixbuf (Itdb_PhotoDB *db,
						  gpointer pixbuf,
						  gint position,
						  gint rotation,
						  GError **error)
{
    g_return_val_if_fail (db, FALSE);
    g_return_val_if_fail (pixbuf, FALSE);

    return itdb_photodb_add_photo_internal (db, NULL, NULL, 0, pixbuf,
					    position, rotation, error);
}


/**
 * itdb_photodb_remove_photo:
 * @db: the #Itdb_PhotoDB to remove the photo from
 * @album: the album to remove the photo from. If album is NULL, then
 * it will first be removed from all photoalbums and then from the
 * photo database as well.
 * @photo: #Itdb_Artwork (photo) to remove.
 *
 * Remove photo. If @album is not the first photoalbum, the photo will
 * be removed from that album only. If @album is NULL or the first
 * photoalbum (Photo Library), the photo will be removed from all
 * albums and the #Itdb_PhotoDB.
 *
 * @photo will be freed and can no longer be used if removed from the
 * first photoalbum.
 */
void itdb_photodb_remove_photo (Itdb_PhotoDB *db,
				Itdb_PhotoAlbum *album,
				Itdb_Artwork *photo)
{
    GList *it;

    g_return_if_fail (db);

    /* If album==NULL, or album is the master album, remove from all
     * albums */
    if ((album == NULL) || (album == g_list_nth_data (db->photoalbums, 0)))
    {
        /* Remove the photo from any albums containing it */
        for (it = db->photoalbums; it != NULL; it = it->next)
	{
            Itdb_PhotoAlbum *_album = it->data;
	    while (g_list_find (_album->members, photo))
	    {
		_album->members = g_list_remove (_album->members, photo);
	    }
        }
        /* Remove the photo from the image list */
	db->photos = g_list_remove (db->photos, photo);
	/* Free the photo */
	itdb_artwork_free (photo);
    }
    /* If album is specified, only remove it from that album */
    else
    {
        album->members = g_list_remove (album->members, photo);
    }
}

/**
 * itdb_photodb_photoalbum_by_name:
 * @db: the #Itdb_PhotoDB to retrieve the album from
 * @albumname: the name of the photoalbum to get or NULL for the
 * master photoalbum.
 *
 * Find the first photoalbum with a given name or the Photo Library
 * Album if called with no name.
 *
 * Return value: a pointer to the first photoalbum named @albumname,
 * else NULL
 */
Itdb_PhotoAlbum *itdb_photodb_photoalbum_by_name (Itdb_PhotoDB *db, const gchar *albumname)
{
	GList *it;

	if( albumname == NULL )
	    return g_list_nth_data (db->photoalbums, 0);

	for (it = db->photoalbums; it != NULL; it = it->next) {
		Itdb_PhotoAlbum *album;

		album = (Itdb_PhotoAlbum *)it->data;
		if( strcmp(album->name, albumname) == 0 )
			return album;
	}
	return NULL;
}

/**
 * itdb_photodb_photoalbum_remove:
 * @db: the #Itdb_PhotoDB to apply changes to
 * @album: the album to be removed from the database
 * @remove_pics: TRUE to remove pics in that album permanently from
 * the database.
 *
 * Remove @album from the Photo Database. If remove_pics is TRUE,
 * remove all photos contained in @album from the Photo Database.
 *
 * Memory used by the removed album will be freed and the album cannot
 * be accessed any more.
 **/
void itdb_photodb_photoalbum_remove (Itdb_PhotoDB *db,
				     Itdb_PhotoAlbum *album,
				     gboolean remove_pics)
{
        GList *it;

        g_return_if_fail (db);
        g_return_if_fail (album);

        /* if remove_pics, iterate over the photos within that album
	 * and remove them from the database */
        if (remove_pics)
	{
            for (it = album->members; it != NULL; it = it->next )
	    {
                Itdb_Artwork *photo = it->data;
                itdb_photodb_remove_photo (db, NULL, photo);
            }
        }
        db->photoalbums = g_list_remove (db->photoalbums, album);
	itdb_photodb_photoalbum_free (album);
}

/**
 * itdb_photodb_photoalbum_add_photo:
 * @db: the #Itdb_PhotoDB to act on
 * @album: the #Itdb_PhotoAlbum to add the photo to
 * @photo: a pointer to the photo (#Itdb_Artwork) to add to the album
 * @position: position where to insert the new photo (-1 to append at
 * the end)
 *
 * Adds a photo already in the library to the specified album
 * @album. Photos are automatically added to the first album (Photo
 * Library) when calling itdb_photodb_add_photo() or
 * itdb_photodb_add_photo_from_data(), so you don't have to use this
 * function to add them there.
 *
 */

void itdb_photodb_photoalbum_add_photo (Itdb_PhotoDB *db,
					Itdb_PhotoAlbum *album,
					Itdb_Artwork *photo,
					gint position)
{
    g_return_if_fail (db);
    g_return_if_fail (album);
    g_return_if_fail (photo);

    album->members = g_list_insert (album->members, photo, position);
}


/**
 * itdb_photodb_photoalbum_create:
 * @db: The database to create a new album in
 * @albumname: the name of the new album
 * @pos: position where to insert the newly created album (-1 for
 * append to end).
 *
 * Create and add a new photoalbum.
 *
 * Return value: the album which was created and added.
 */
Itdb_PhotoAlbum *itdb_photodb_photoalbum_create (Itdb_PhotoDB *db,
						 const gchar *albumname,
						 gint pos)
{
	Itdb_PhotoAlbum *album;

	g_return_val_if_fail (db, NULL);
	g_return_val_if_fail (albumname, NULL);

	album = g_new0 (Itdb_PhotoAlbum, 1);
	album->album_type = 2; /* normal album, set to 1 for Photo Library */
	album->name = g_strdup(albumname);
	db->photoalbums = g_list_insert (db->photoalbums, album, pos);

	return album;
}

/**
 * itdb_photodb_write:
 * @photodb: the #Itdb_PhotoDB to write to disk
 * @error: return location for a #GError or NULL
 *
 * Write out a PhotoDB.
 *
 * FIXME: error is not set yet.
 *
 * Return value: TRUE on success, FALSE on error, in which case @error is
 * set accordingly.
 **/
gboolean itdb_photodb_write (Itdb_PhotoDB *photodb, GError **error)
{
    gint result;
    GList *gl;
    gint32 id, prev_id;

    g_return_val_if_fail (photodb, FALSE);
    g_return_val_if_fail (photodb->device, FALSE);

    if (photodb->device->byte_order == 0)
	itdb_device_autodetect_endianess (photodb->device);

    /* set up photo_ids */
    id = 0x40;
    for (gl=photodb->photos; gl; gl=gl->next)
    {
	Itdb_Artwork *photo = gl->data;
	g_return_val_if_fail (photo, FALSE);
	photo->id = id;
	++id;
    }
    /* set up album_ids -- this is how my iPod Nano does it... */
    prev_id = 0x64;
    id = prev_id + g_list_length (photodb->photos);
    for (gl=photodb->photoalbums; gl; gl=gl->next)
    {
	Itdb_PhotoAlbum *album = gl->data;
	g_return_val_if_fail (album, FALSE);
	album->album_id = id;
	album->prev_album_id = prev_id;
	++id;
	++prev_id;
	if (gl != photodb->photoalbums)
	{   /* except for the first album */
	    prev_id += g_list_length (album->members);
	}
    }

    result = ipod_write_photo_db (photodb);

    /* Write SysInfo file if it has changed */
    if (!error || !(*error))
    {
	if (photodb->device->sysinfo_changed)
	{
	    itdb_device_write_sysinfo (photodb->device, error);
	}
    }

    if (result == -1)
	return FALSE;
    else
	return TRUE;
}
