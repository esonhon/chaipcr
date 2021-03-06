/* * Chai PCR - Software platform for Open qPCR and Chai's Real-Time PCR instruments.
 * For more information visit http://www.chaibio.com
 *
 * Copyright 2016 Chai Biotechnologies Inc. <info@chaibio.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef SOCIINCLUDES_H
#define SOCIINCLUDES_H

#include <soci/soci.h>
//#include <soci/sqlite3/soci-sqlite3.h>
#include <soci/mysql/soci-mysql.h>

#include <boost/date_time.hpp>
#include <boost/date_time/posix_time/ptime.hpp>

namespace soci
{

template<>
struct type_conversion<boost::posix_time::ptime>
{
    typedef std::tm base_type;

    static void from_base(base_type const &in, soci::indicator indicator, boost::posix_time::ptime &out)
    {
        if (indicator != soci::i_null)
            out = boost::posix_time::ptime_from_tm(in);
        else
            out = boost::posix_time::not_a_date_time;
    }

    static void to_base(boost::posix_time::ptime const &in, base_type &out, soci::indicator &indicator)
    {
        out = boost::posix_time::to_tm(in);
        indicator = soci::i_ok;
    }
};

template<>
struct type_conversion<Stage::Type>
{
    typedef std::string base_type;

    static void from_base(base_type const &in, soci::indicator indicator, Stage::Type &out)
    {
        if (indicator != soci::i_null)
        {
            if (in == "holding")
                out = Stage::Holding;
            else if (in == "cycling")
                out = Stage::Cycling;
            else if (in == "meltcurve")
                out = Stage::Meltcurve;
            else
                out = Stage::None;
        }
        else
            out = Stage::None;
    }

    static void to_base(Stage::Type const &in, base_type &out, soci::indicator &indicator)
    {
        switch (in)
        {
        case Stage::Holding:
            out = "holding";
            indicator = soci::i_ok;

            break;

        case Stage::Cycling:
            out = "cycling";
            indicator = soci::i_ok;

            break;

        case Stage::Meltcurve:
            out = "meltcurve";
            indicator = soci::i_ok;

            break;

        default:
            indicator = soci::i_null;
            break;
        }
    }
};

template<>
struct type_conversion<Experiment::CompletionStatus>
{
    typedef std::string base_type;

    static void from_base(base_type const &in, soci::indicator indicator, Experiment::CompletionStatus &out)
    {
        if (indicator != soci::i_null)
        {
            if (in == "success")
                out = Experiment::Success;
            else if (in == "failed")
                out = Experiment::Failed;
            else if (in == "aborted")
                out = Experiment::Aborted;
            else
                out = Experiment::None;
        }
        else
            out = Experiment::None;
    }

    static void to_base(Experiment::CompletionStatus const &in, base_type &out, soci::indicator &indicator)
    {
        switch (in)
        {
        case Experiment::Success:
            out = "success";
            indicator = soci::i_ok;

            break;

        case Experiment::Failed:
            out = "failed";
            indicator = soci::i_ok;

            break;

        case Experiment::Aborted:
            out = "aborted";
            indicator = soci::i_ok;

            break;

        default:
            indicator = soci::i_null;
            break;
        }
    }
};


template<>
struct type_conversion<Experiment::Type>
{
    typedef std::string base_type;

    static void from_base(base_type const &in, soci::indicator indicator, Experiment::Type &out)
    {
        if (indicator != soci::i_null)
        {
            if (in == "diagnostic")
                out = Experiment::DiagnosticType;
            else if (in == "calibration")
                out = Experiment::CalibrationType;
            else
                out = Experiment::NoneType;
        }
        else
            out = Experiment::NoneType;
    }

    static void to_base(Experiment::Type const &in, base_type &out, soci::indicator &indicator)
    {
        switch (in)
        {
        case Experiment::DiagnosticType:
            out = "diagnostic";
            indicator = soci::i_ok;

            break;

        default:
            indicator = soci::i_null;
            break;
        }
    }
};

}

#endif // SOCIINCLUDES_H
