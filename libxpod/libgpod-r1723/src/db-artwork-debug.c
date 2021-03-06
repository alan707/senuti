/*
 *  Copyright (C) 2005 Christophe Fergeau
 *
 * 
 *  The code contained in this file is free software; you can redistribute
 *  it and/or modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either version
 *  2.1 of the License, or (at your option) any later version.
 *  
 *  This file is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *  
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this code; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 * 
 *  iTunes and iPod are trademarks of Apple
 * 
 *  This product is not supported/written/published by Apple!
 *
 */

#include "db-artwork-debug.h"

/* FIXME: endianness (whole file) */

#ifdef DEBUG_ARTWORKDB
G_GNUC_INTERNAL void
dump_mhif (MhifHeader *mhif)
{

	g_print ("MHIF (%d):\n", sizeof (MhifHeader));
	g_print ("\tHeader length: %d\n", GINT_FROM_LE (mhif->header_len));
	g_print ("\tTotal length: %d\n", GINT_FROM_LE (mhif->total_len));
	g_print ("\tUnknown1: %08x\n", GINT_FROM_LE (mhif->unknown1));
	g_print ("\tCorrelation ID: %d (=> F%d_1.ithmb)\n", 
		 GINT_FROM_LE (mhif->correlation_id),
		 GINT_FROM_LE (mhif->correlation_id));
	g_print ("\tImage size: %d bytes\n", GINT_FROM_LE (mhif->image_size));
}

G_GNUC_INTERNAL void
dump_mhia (MhiaHeader *mhia)
{
	g_print ("MHIA (%d):\n", sizeof (MhiaHeader));
	g_print ("\tHeader length: %d\n", GINT_FROM_LE (mhia->header_len));
	g_print ("\tTotal length: %d\n", GINT_FROM_LE (mhia->total_len));
	g_print ("\tUnknown1: %08x\n", GINT_FROM_LE (mhia->unknown1));
	g_print ("\tImage ID: %08x\n", GINT_FROM_LE (mhia->image_id));
}

static char *
get_utf16_string (void* buffer, gint length)
{
	char *result;
	gunichar2 *tmp;
	int i;
	/* Byte-swap the utf16 characters if necessary (I'm relying
	 * on gcc to optimize most of this code away on LE platforms)
	 */
	tmp = g_memdup (buffer, length);
	for (i = 0; i < length/2; i++) {
		tmp[i] = GINT16_FROM_LE (tmp[i]);
	}
	result = g_utf16_to_utf8 (tmp, length/2, NULL, NULL, NULL);
	g_free (tmp);

	return result;	
}

G_GNUC_INTERNAL void
dump_mhod_type_1 (MhodHeaderArtworkType1 *mhod1) 
{
	g_print ("MHOD [artwork type 1] (%d):\n", sizeof (MhodHeaderArtworkType1));
	g_print ("\tHeader length: %d\n", GINT_FROM_LE (mhod1->header_len));
	g_print ("\tTotal length: %d\n", GINT_FROM_LE (mhod1->total_len));
	g_print ("\tPadding: %04x\n", GINT_FROM_LE (mhod1->padding));
	g_print ("\tType: %04x\n", GINT_FROM_LE (mhod1->type));
	g_print ("\tUnknown1: %08x\n", GINT_FROM_LE (mhod1->unknown1));
	g_print ("\tUnknown2: %08x\n", GINT_FROM_LE (mhod1->unknown2));
	g_print ("\tString length: %u\n", GINT_FROM_LE (mhod1->string_len));
	g_print ("\tUnknown3: %08x\n", GINT_FROM_LE (mhod1->unknown3));
	g_print ("\tUnknown4: %08x\n", GINT_FROM_LE (mhod1->unknown4));
	/* FIXME: do I need to translate UTF-8 to local encoding? */
	g_print ("\tString: \"%.*s\"\n", GINT_FROM_LE (mhod1->string_len), mhod1->string);
}

G_GNUC_INTERNAL void 
dump_mhod_type_3 (ArtworkDB_MhodHeaderArtworkType3 *mhod3) 
{
	gchar *str;

	g_print ("MHOD [artwork type 3] (%d):\n", sizeof (ArtworkDB_MhodHeaderArtworkType3));
	g_print ("\tHeader length: %d\n", GINT_FROM_LE (mhod3->header_len));
	g_print ("\tTotal length: %d\n", GINT_FROM_LE (mhod3->total_len));
	g_print ("\tPadding: %04x\n", GINT_FROM_LE (mhod3->padding));
	g_print ("\tType: %04x\n", GINT_FROM_LE (mhod3->type));
	g_print ("\tUnknown1: %08x\n", GINT_FROM_LE (mhod3->unknown1));
	g_print ("\tUnknown2: %08x\n", GINT_FROM_LE (mhod3->unknown2));
	g_print ("\tString length: %u\n", GINT_FROM_LE (mhod3->string_len));
	g_print ("\tMHOD version: %u\n", GINT_FROM_LE (mhod3->mhod_version));
	g_print ("\tUnknown4: %08x\n", GINT_FROM_LE (mhod3->unknown4));
	str = get_utf16_string (mhod3->string, mhod3->string_len);
	g_print ("\tString: %s\n", str);
	g_free (str);
}

G_GNUC_INTERNAL void
dump_mhni (MhniHeader *mhni) 
{
	unsigned int width  = GINT16_FROM_LE (mhni->image_width);
	unsigned int height = GINT16_FROM_LE (mhni->image_height);

	g_print ("MHNI (%d):\n", sizeof (MhniHeader));
	g_print ("\tHeader length: %d\n", GINT_FROM_LE (mhni->header_len));
	g_print ("\tTotal length: %d\n", GINT_FROM_LE (mhni->total_len));
	g_print ("\tNumber of children: %08x\n", GINT_FROM_LE (mhni->num_children));
	g_print ("\tCorrelation ID: %d (=> F%d_1.ithmb)\n", 
		 GINT_FROM_LE (mhni->correlation_id),
		 GINT_FROM_LE (mhni->correlation_id));
	g_print ("\tithmb offset: %u bytes\n", GINT_FROM_LE (mhni->ithmb_offset));
	g_print ("\tImage size: %u bytes\n", GINT_FROM_LE (mhni->image_size));
	g_print ("\tVertical padding: %d\n", GINT_FROM_LE (mhni->vertical_padding));
	g_print ("\tHorizontal padding: %d\n", GINT_FROM_LE (mhni->horizontal_padding));
	g_print ("\tImage dimensions: %ux%u\n", width, height);
}

G_GNUC_INTERNAL void
dump_mhod (ArtworkDB_MhodHeader *mhod) 
{
	g_print ("MHOD (%d):\n", sizeof (ArtworkDB_MhodHeader));
	g_print ("\tHeader length: %d\n", GINT_FROM_LE (mhod->header_len));
	g_print ("\tTotal length: %d\n", GINT_FROM_LE (mhod->total_len));
	g_print ("\tType: %08x\n", GINT_FROM_LE (mhod->type));
	g_print ("\tUnknown1: %08x\n", GINT_FROM_LE (mhod->unknown1));
	g_print ("\tUnknown2: %08x\n", GINT_FROM_LE (mhod->unknown2));
}

G_GNUC_INTERNAL void
dump_mhii (MhiiHeader *mhii)
{
	g_print ("MHII (%d):\n", sizeof (MhiiHeader));
	g_print ("\tHeader length: %d\n", GINT_FROM_LE (mhii->header_len));
	g_print ("\tTotal length: %d\n", GINT_FROM_LE (mhii->total_len));
	g_print ("\tNumber of children: %d\n", GINT_FROM_LE (mhii->num_children));
	g_print ("\tImage ID: %08x\n", GINT_FROM_LE (mhii->image_id));
	g_print ("\tSong ID: %016llx\n", GINT64_FROM_LE (mhii->song_id));
	g_print ("\tUnknown4: %08x\n", GINT_FROM_LE (mhii->unknown4));
	g_print ("\tRating: %08x\n", GINT_FROM_LE (mhii->rating));
	g_print ("\tUnknown6: %08x\n", GINT_FROM_LE (mhii->unknown6));
	g_print ("\tOrig Date: %08x\n", GINT_FROM_LE (mhii->orig_date));
	g_print ("\tDigitised Date: %08x\n", GINT_FROM_LE (mhii->digitized_date));
	g_print ("\tImage size: %d bytes\n", GINT_FROM_LE (mhii->orig_img_size));
}

G_GNUC_INTERNAL void
dump_mhl (MhlHeader *mhl, const char *id)
{
	GString *str;

	str = g_string_new (id);
	g_string_ascii_up (str);
	g_print ("%s (%d):\n", str->str, sizeof (MhlHeader));
	g_print ("\tHeader size: %d\n", GINT_FROM_LE (mhl->header_len));
	g_print ("\tNumber of items: %d\n", GINT_FROM_LE (mhl->num_children));
	g_string_free (str, TRUE);
}

G_GNUC_INTERNAL void
dump_mhsd (ArtworkDB_MhsdHeader *mhsd)
{
	g_print ("MHSD (%d):\n", sizeof (ArtworkDB_MhsdHeader));
	g_print ("\tHeader length: %d\n", GINT_FROM_LE (mhsd->header_len));
	g_print ("\tTotal length: %d\n", GINT_FROM_LE (mhsd->total_len));
	g_print ("\tIndex: %d ", GINT16_FROM_LE (mhsd->index));
	switch (GINT16_FROM_LE (mhsd->index)) {
	case MHSD_IMAGE_LIST:
		g_print ("(Image list)\n");
		break;
	case MHSD_ALBUM_LIST:
		g_print ("(Album list)\n");
		break;
	case MHSD_FILE_LIST:
		g_print ("(File list)\n");
		break;

	default:
		g_print ("(Unknown index\n");
		break;
	}
}

G_GNUC_INTERNAL void
dump_mhfd (MhfdHeader *mhfd)
{
	g_print ("MHFD (%d):\n", sizeof (MhfdHeader));
	g_print ("\tHeader length: %d\n", GINT_FROM_LE (mhfd->header_len));
	g_print ("\tTotal length: %d\n", GINT_FROM_LE (mhfd->total_len));
	g_print ("\tUnknown1: %08x\n", GINT_FROM_LE (mhfd->unknown1));
	g_print ("\tUnknown2: %08x\n", GINT_FROM_LE (mhfd->unknown2));
	g_print ("\tNumber of children: %d\n", GINT_FROM_LE (mhfd->num_children));
	g_print ("\tUnknown3: %08x\n", GINT_FROM_LE (mhfd->unknown3));
	g_print ("\tNext id: %08x\n", GINT_FROM_LE (mhfd->next_id));
	g_print ("\tUnknown5: %016llx\n", GINT64_FROM_LE (mhfd->unknown5));
	g_print ("\tUnknown6: %016llx\n", GINT64_FROM_LE (mhfd->unknown6));
	g_print ("\tunknown_flag1: %04x\n", GINT_FROM_LE (mhfd->unknown_flag1));
	g_print ("\tUnknown8: %08x\n", GINT_FROM_LE (mhfd->unknown8));
	g_print ("\tUnknown9: %08x\n", GINT_FROM_LE (mhfd->unknown9));
	g_print ("\tUnknown10: %08x\n", GINT_FROM_LE (mhfd->unknown10));
	g_print ("\tUnknown11: %08x\n", GINT_FROM_LE (mhfd->unknown11));
}

G_GNUC_INTERNAL void
dump_mhba (MhbaHeader *mhba)
{
	g_print ("MHBA (%d):\n", sizeof (MhbaHeader));
	g_print ("\tHeader length: %d\n", GINT_FROM_LE (mhba->header_len));
	g_print ("\tTotal length: %d\n", GINT_FROM_LE (mhba->total_len));
	g_print ("\tNumber of Data Objects: %d\n", GINT_FROM_LE (mhba->num_mhods));
	g_print ("\tNumber of pictures in the album: %d\n", GINT_FROM_LE (mhba->num_mhias));
	g_print ("\tPlaylist ID: %08x\n", GINT_FROM_LE (mhba->playlist_id));
	g_print ("\tUnknown2: %08x\n", GINT_FROM_LE (mhba->unknown2));
	g_print ("\tUnknown3: %04x\n", GINT_FROM_LE (mhba->unknown3));
	g_print ("\tMaster playlist: %02x\n", GINT_FROM_LE (mhba->master));
	g_print ("\tRepeat: %02x\n", GINT_FROM_LE (mhba->repeat));
	g_print ("\tRandom: %02x\n", GINT_FROM_LE (mhba->random));
	g_print ("\tTransition direction: %02x\n", GINT_FROM_LE (mhba->transition_direction));
	g_print ("\tSlide duration: %08x\n", GINT_FROM_LE (mhba->slide_duration));
	g_print ("\tPrev playlist ID: %08x\n", GINT_FROM_LE (mhba->prev_playlist_id));
}

#endif
