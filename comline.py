from __future__ import print_function

import argparse
import os.path
import distutils.util

class ComLine():
	'Class for implementing command line options'


	def __init__(self, args):
		parser = argparse.ArgumentParser()
		parser.add_argument("-f", "--file",
							dest='infile',
							required=True,
							help="Specify the output from add_distances.pl)"
		)

		self.args = parser.parse_args()

		#check if files exist
		self.exists( self.args.infile )

	def exists(self, filename):
		if( os.path.isfile(filename) != True ):
			print(filename, "does not exist")
			print("Exiting program...")
			print("")
			raise SystemExit
