public class TemperatureConverter {
    // Takes a Fahrenheit temperature and returns the Celsius equivalent.
    public static Decimal fhToCels(Decimal fh) {
        Decimal cels = (fh - 32) * 5/9;
        System.debug('Copado Rocks!!!');
        return cels.setScale(2);
        //Additional comment overwrite v1
    }
}