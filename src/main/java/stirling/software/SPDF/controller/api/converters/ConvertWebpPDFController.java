package stirling.software.SPDF.controller.api.converters;

import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import javax.imageio.IIOImage;
import javax.imageio.ImageIO;
import javax.imageio.ImageWriteParam;
import javax.imageio.ImageWriter;
import javax.imageio.stream.ImageOutputStream;

import org.apache.pdfbox.rendering.ImageType;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import io.github.pixee.security.Filenames;

import stirling.software.SPDF.model.api.converters.ConvertToPdfRequest;
import stirling.software.SPDF.utils.PdfUtils;

@RestController
@RequestMapping("/api/v1/convert")
public class ConvertWebpPDFController {

    private static final Logger logger = LoggerFactory.getLogger(ConvertWebpPDFController.class);

    @PostMapping(consumes = "multipart/form-data", value = "/pdf/webp")
    public ResponseEntity<byte[]> convertToWebp(@ModelAttribute ConvertToPdfRequest request)
            throws Exception {
        MultipartFile file = request.getFileInput()[0]; // Assuming only one file is uploaded

        // Convert PDF to PNG
        byte[] pngData = convertPdfToPng(file);

        // Save PNG to a temporary file
        Path tempPngPath = Files.createTempFile("temp_png", ".png");
        Files.write(tempPngPath, pngData);

        // Read PNG as BufferedImage
        BufferedImage pngImage = ImageIO.read(tempPngPath.toFile());

        // Create a temporary directory for the output WebP files
        Path tempOutputDir = Files.createTempDirectory("webp_output");

        try {
            // WebP konvertieren und speichern
            Path webpFilePath = tempOutputDir.resolve("output.webp");
            convertPngToWebp(pngImage, webpFilePath);

            // Check if the WebP file has been created and has data
            if (Files.size(webpFilePath) == 0) {
                throw new IOException("The WebP file is empty.");
            }

            // Create a ZIP file of the PNG and WebP images
            ByteArrayOutputStream zipOutputStream = new ByteArrayOutputStream();
            try (ZipOutputStream zos = new ZipOutputStream(zipOutputStream)) {
                // Add the PNG file to the ZIP
                zos.putNextEntry(new ZipEntry(tempPngPath.getFileName().toString()));
                Files.copy(tempPngPath, zos);
                zos.closeEntry();

                // Add the WebP file to the ZIP
                zos.putNextEntry(new ZipEntry(webpFilePath.getFileName().toString()));
                Files.copy(webpFilePath, zos);
                zos.closeEntry();
            }

            // Clean up temporary files
            Files.walk(tempOutputDir).map(Path::toFile).forEach(File::delete);
            Files.deleteIfExists(tempOutputDir);
            Files.deleteIfExists(tempPngPath);

            HttpHeaders headers = new HttpHeaders();
            headers.add(
                    HttpHeaders.CONTENT_DISPOSITION,
                    "attachment; filename=\"converted_images.zip\"");
            return ResponseEntity.ok().headers(headers).body(zipOutputStream.toByteArray());
        } catch (IOException e) {
            logger.error("Error during conversion", e);
            throw e;
        }
    }

    private byte[] convertPdfToPng(MultipartFile file) throws Exception {
        String imageFormat = "png";
        String singleOrMultiple = "single"; // Assuming single image for simplicity
        String colorType = "rgb"; // Assuming RGB color type for simplicity
        String dpi = "300"; // Assuming 300 DPI for simplicity

        byte[] pdfBytes = file.getBytes();
        ImageType colorTypeResult = ImageType.RGB;
        if ("greyscale".equals(colorType)) {
            colorTypeResult = ImageType.GRAY;
        } else if ("blackwhite".equals(colorType)) {
            colorTypeResult = ImageType.BINARY;
        }
        // returns bytes for image
        boolean singleImage = "single".equals(singleOrMultiple);
        byte[] result = null;
        String filename =
                Filenames.toSimpleFileName(file.getOriginalFilename())
                        .replaceFirst("[.][^.]+$", "");

        result =
                PdfUtils.convertFromPdf(
                        pdfBytes,
                        imageFormat.toUpperCase(),
                        colorTypeResult,
                        singleImage,
                        Integer.valueOf(dpi),
                        filename);

        if (result == null || result.length == 0) {
            logger.error("resultant bytes for {} is null, error converting ", filename);
        }

        return result;
    }

    private void convertPngToWebp(BufferedImage pngImage, Path webpFilePath) throws IOException {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        try {
            ImageWriter writer = ImageIO.getImageWritersByMIMEType("image/webp").next();
            ImageWriteParam param = writer.getDefaultWriteParam();
            try (ImageOutputStream ios = ImageIO.createImageOutputStream(baos)) {
                writer.setOutput(ios);
                writer.write(null, new IIOImage(pngImage, null, null), param);
            } finally {
                writer.dispose();
            }
            Files.write(webpFilePath, baos.toByteArray());
        } catch (Exception e) {
            logger.error("Error converting PNG to WebP", e);
            throw new IOException("Error converting PNG to WebP", e);
        }
    }
}
