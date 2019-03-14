volume = DicomImageVolume('E:\Contour Validation\Data\2010_12_08\GdT1wMR','Verbose',true);
centreCoords = volume.getCentreCoordsOfVolume();
fov = FieldOfViewGeometry([1 0 0], [0 1 0], [0 0 0], centreCoords);

fov.setFieldOfViewWidthHeightToFitVolume(volume, 10, 10);
fov.setFieldOfViewWidthHeightToFitVolume(volume, 15, 10);
fov.setFieldOfViewWidthHeightToFitVolume(volume, 10, 15);