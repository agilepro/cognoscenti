/*
 * Thumbnail.java (requires Java 1.2+)
 */
package org.socialbiz.cog.util;

import java.awt.Container;
import java.awt.Graphics2D;
import java.awt.Image;
import java.awt.MediaTracker;
import java.awt.RenderingHints;
import java.awt.Toolkit;
import java.awt.image.BufferedImage;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;

import javax.imageio.ImageIO;

import org.imgscalr.Scalr;

import com.purplehillsbooks.json.JSONException;

public class Thumbnail {

	public static synchronized void scalePhoto(File inFileName, OutputStream mainOut,
			int thumbWidth, int thumbHeight, int quality) throws Exception {
		FileInputStream fis = new FileInputStream(inFileName);
		try {
			scalePhoto(fis, mainOut, thumbWidth, thumbHeight, quality);
		}
		catch (Exception e) {
			throw new JSONException("Unable to read file {0}", e, inFileName);
		}
		finally {
			fis.close();
		}
	}

	public static synchronized void scalePhoto(InputStream inStream, OutputStream mainOut,
			int thumbWidth, int thumbHeight, int quality) throws Exception {
		if (thumbWidth < 0) {
			throw new JSONException("a width of '{0}' makes no sense", thumbWidth);
		}
		if (thumbHeight < 0) {
			throw new JSONException("a height of '{0}' makes no sense", thumbHeight);
		}
		try {
			// load image from INFILE
			BufferedImage image = javax.imageio.ImageIO.read(inStream);

			if (image == null) {
				throw new JSONException("Unable to read the the input stream");
			}

			// determine thumbnail size from WIDTH and HEIGHT
			// if asked for negative thumb size, then don't scale
			int imageWidth = image.getWidth(null);
			int imageHeight = image.getHeight(null);
			if (imageWidth < 0 || imageHeight < 0) {
				throw new JSONException("Image appears damaged with width of '{0}' and height of '{1}'", imageWidth, imageHeight);
			}
			if (thumbWidth <= 0) {
				thumbWidth = imageWidth;
				thumbHeight = imageHeight;
			}
			else if (thumbWidth > imageWidth && thumbHeight > imageHeight) {
				// avoid expanding image ... shrink only
				thumbWidth = imageWidth;
				thumbHeight = imageHeight;
			}
			double thumbRatio = (double) thumbWidth / (double) thumbHeight;
			double imageRatio = (double) imageWidth / (double) imageHeight;
			if (thumbRatio < imageRatio) {
				thumbHeight = (int) (thumbWidth / imageRatio);
			}
			else {
				thumbWidth = (int) (thumbHeight * imageRatio);
			}

			// draw original image to thumbnail image object and
			// scale it to the new size on-the-fly
			BufferedImage thumbImage = org.imgscalr.Scalr.resize(image, Scalr.Method.ULTRA_QUALITY,
					Scalr.Mode.FIT_EXACT, thumbWidth, thumbHeight, Scalr.OP_ANTIALIAS);

			BufferedOutputStream out = new BufferedOutputStream(mainOut);

			ImageIO.write(thumbImage, "jpg", out);

			out.close();
		}
		catch (Exception e) {
			throw new JSONException("Unable to resize image to {0} by {1}", e, thumbWidth, thumbHeight);
		}
	}

	public static void makeThumbnail(File inFileName, String outFileName, int thumbWidth,
			int thumbHeight, int quality) throws Exception {
		scalePhoto(inFileName, new FileOutputStream(outFileName), thumbWidth, thumbHeight, quality);
	}

	/**
	 * This makes a thumbnail whic his square, and fills the square. First is
	 * shrinks the image so that the short dimension is the requested size. Then
	 * it pulls a square out of the middle of the image, and saves it as a JPG
	 * image
	 */
	public static void makeSquare(String inFileName, String outFileName, int size, int quality)
			throws Exception {
		BufferedOutputStream out = new BufferedOutputStream(new FileOutputStream(outFileName));
		makeSquare(inFileName, out, size, quality);
		out.close();
	}

	public static synchronized void makeSquare(String inFileName, OutputStream out, int size,
			int quality) throws Exception {

		// load image from INFILE
		Toolkit toolkit = Toolkit.getDefaultToolkit();
		Image image = toolkit.getImage(inFileName);
		MediaTracker mediaTracker = new MediaTracker(new Container());
		mediaTracker.addImage(image, 0);
		mediaTracker.waitForID(0);

		// determine thumbnail size from WIDTH and HEIGHT
		int imageWidth = image.getWidth(null);
		int imageHeight = image.getHeight(null);
		int thumbWidth = size;
		int thumbHeight = size;
		int offSetX = 0;
		int offSetY = 0;
		double imageRatio = (double) imageWidth / (double) imageHeight;
		if (imageWidth < imageHeight) {
			thumbHeight = (int) (size / imageRatio);
			offSetY = (thumbHeight - size) / 2;
		}
		else {
			thumbWidth = (int) (size * imageRatio);
			offSetX = (thumbWidth - size) / 2;
		}

		// draw original image to thumbnail image object and
		// scale it to the new size on-the-fly
		BufferedImage thumbImage = new BufferedImage(thumbWidth, thumbHeight,
				BufferedImage.TYPE_INT_RGB);
		Graphics2D graphics2D = thumbImage.createGraphics();
		// graphics2D.setClip(offSetX,offSetY,size,size);
		graphics2D.setRenderingHint(RenderingHints.KEY_INTERPOLATION,
				RenderingHints.VALUE_INTERPOLATION_BILINEAR);
		graphics2D.drawImage(image, 0, 0, thumbWidth, thumbHeight, null);

		// pull the square segment out of the middle
		BufferedImage squareImage = thumbImage.getSubimage(offSetX, offSetY, size, size);

		ImageIO.write(squareImage, "jpg", out);

	}

	public static synchronized void makeSquareFile(File inFileName, File outFile, int size) throws Exception {

		// load image from INFILE
		Toolkit toolkit = Toolkit.getDefaultToolkit();
		Image image = toolkit.getImage(inFileName.toString());

		//this is extremely goofy code.   The library can not simply read and write
		//a file.  For some reason, it has to be entered into a cache, and then
		//later it must be read from that cache.  No idea why.
		//Probably need to read and possibly simply the image editor code.
		//for now, this magic piece of code seems to work.

		MediaTracker mediaTracker = new MediaTracker(new Container());
		mediaTracker.addImage(image, 0);
		mediaTracker.waitForID(0);

		// determine thumbnail size from WIDTH and HEIGHT
		int imageWidth = image.getWidth(null);
		int imageHeight = image.getHeight(null);
		int thumbWidth = size;
		int thumbHeight = size;
		int offSetX = 0;
		int offSetY = 0;
		double imageRatio = (double) imageWidth / (double) imageHeight;
		if (imageWidth < imageHeight) {
			thumbHeight = (int) (size / imageRatio);
			offSetY = (thumbHeight - size) / 2;
		}
		else {
			thumbWidth = (int) (size * imageRatio);
			offSetX = (thumbWidth - size) / 2;
		}

		// draw original image to thumbnail image object and
		// scale it to the new size on-the-fly
		BufferedImage thumbImage = new BufferedImage(thumbWidth, thumbHeight,
				BufferedImage.TYPE_INT_RGB);
		Graphics2D graphics2D = thumbImage.createGraphics();
		// graphics2D.setClip(offSetX,offSetY,size,size);
		graphics2D.setRenderingHint(RenderingHints.KEY_INTERPOLATION,
				RenderingHints.VALUE_INTERPOLATION_BILINEAR);
		graphics2D.drawImage(image, 0, 0, thumbWidth, thumbHeight, null);

		// pull the square segment out of the middle
		BufferedImage squareImage = thumbImage.getSubimage(offSetX, offSetY, size, size);

		FileOutputStream out = new FileOutputStream(outFile);

		ImageIO.write(squareImage, "jpg", out);

		out.close();

		//this class seems to be storing images for some reason, and preferring
		//the last image you stored to the one you just gave it.
		//Images are stored until server reboot.
		//this hopefully will prevent waste of memory
		mediaTracker.removeImage(image);
	}

	public static void main(String[] args) throws Exception {
		try {
			if (args.length > 4 || args.length < 2) {
				throw new JSONException(
						"Usage: java Thumbnail INFILE OUTFILE [WIDTH] [QUALITY]");
			}
			String inFileName = args[0];
			File inFile = new File(inFileName);
			if (!inFile.exists()) {
				throw new JSONException("File '{0}' does not exist.", inFileName);
			}
			String outFileName = args[1];
			File outFile = new File(outFileName);
			if (outFile.exists()) {
				throw new JSONException(
						"File '{0}' already exists -- this program does not write over existing files.  Remove it first.", outFileName);
			}

			int thumbWidth = 225;
			int quality = 90;

			switch (args.length) {
			case 4:
				quality = Integer.parseInt(args[3]);
			case 3:
				thumbWidth = Integer.parseInt(args[2]);
			default:
			}

			makeSquare(inFileName, outFileName, thumbWidth, quality);

			System.out.println("Done.");
			System.exit(0);
		}
		catch (Exception e) {
			e.printStackTrace();
			System.exit(1);
		}
	}

}
