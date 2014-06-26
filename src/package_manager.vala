/*-
 *  Copyright (c) 2014 George Sofianos
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *  Authored by: George Sofianos <georgesofianosgr@gmail.com>
 */

 public class Radio.PackageManager : GLib.Object {

    private static Json.Parser parser;
    private static Json.Builder builder;
    private static double pkg_version {get;set;default=1.0;}

    public static Radio.Station[] parse (string path) throws Radio.Error{

        if(parser == null)
            parser = new Json.Parser ();

        Radio.Station[] stations_array = null;

        try {
            parser.load_from_file (path);
        } catch (GLib.Error e) {
            stderr.printf(e.message);
            throw new Radio.Error.GENERAL ("Could not parse file");
        }

        var root = parser.get_root();
        var obj = root.get_object();

        // Check if object is valid
        if(obj.has_member ("pkg_version") && obj.has_member ("stations")) {
            /* DEBUG
            stdout.printf ("Pkg Version : %.1f\n",obj.get_double_member("pkg_version"));
            stdout.printf ("Pkg Name : %s\n\n",obj.get_string_member("pkg_name"));*/

            var stations = obj.get_array_member ("stations");
            var stations_length = stations.get_length();

            stations_array = new Radio.Station[stations_length];
            for(var i = 0; i < stations_length; i++) {

                var station_object = stations.get_object_element(i);

                var name = station_object.get_string_member ("Name");
                var genre = station_object.get_string_member ("Genre");
                var url = station_object.get_string_member ("Url");
                var station = new Radio.Station (-1,name,url,genre);

                stations_array[i] = station;
            }

        } else {
            stderr.printf("Error, package corrupted\n");
        }

        return stations_array;
    }

    public static void extract (Gee.ArrayList<Radio.Station> stations,string file_path) throws GLib.Error {

        if(builder == null)
            builder = new Json.Builder ();
        else
            builder.reset ();

        builder.begin_object ();
        builder.set_member_name ("pkg_version");
        builder.add_double_value (pkg_version);
        builder.set_member_name ("stations");
        builder.begin_array ();

        foreach (Radio.Station station in stations) {
            builder.begin_object ();

            builder.set_member_name ("Name");
            builder.add_string_value (station.name);
            builder.set_member_name ("Genre");
            builder.add_string_value (station.genre);
            builder.set_member_name ("Url");
            builder.add_string_value (station.url);

            builder.end_object ();
        }

        builder.end_array ();
        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        //string str = generator.to_data (null);
        //stdout.printf(str);
        try {
            generator.to_file(file_path);
        } catch (GLib.Error error) {
            throw error;
        }

    }
 }